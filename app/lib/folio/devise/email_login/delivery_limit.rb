# frozen_string_literal: true

class Folio::Devise::EmailLogin::DeliveryLimit
  # One atomic operation covers the rolling window and cooldown, including
  # unknown addresses. Keys expire without retaining account lookup results.
  SCRIPT = <<~LUA
    local key = KEYS[1]
    local now = tonumber(ARGV[1])
    local window = tonumber(ARGV[2])
    local cooldown = tonumber(ARGV[3])
    local limit = tonumber(ARGV[4])
    redis.call('ZREMRANGEBYSCORE', key, '-inf', now - window)
    local last = redis.call('ZREVRANGE', key, 0, 0, 'WITHSCORES')
    local wait = 0
    if #last > 0 then
      wait = math.max(0, tonumber(last[2]) + cooldown - now)
    end
    if redis.call('ZCARD', key) >= limit then
      local first = redis.call('ZRANGE', key, 0, 0, 'WITHSCORES')
      wait = math.max(wait, tonumber(first[2]) + window - now)
    end
    if wait > 0 then return math.ceil(wait) end
    redis.call('ZADD', key, now, ARGV[5])
    redis.call('EXPIRE', key, window)
    return 0
  LUA

  def self.consume!(site:, email:)
    retry_after = redis.eval(SCRIPT, keys: [key(site:, email:)],
                            argv: [Time.current.to_f, Folio::Devise::EmailLogin::DELIVERY_WINDOW.to_i,
                                   Folio::Devise::EmailLogin::RESEND_INTERVAL.to_i,
                                   Folio::Devise::EmailLogin::DELIVERY_LIMIT, SecureRandom.hex(16)])
    if retry_after.positive?
      Folio::Devise::EmailLogin.instrument("throttled", site_id: site.id)
      raise Folio::Devise::EmailLogin::Throttled.new(retry_after:)
    end
  rescue Redis::BaseError
    raise Folio::Devise::EmailLogin::Unavailable, "Email login rate limiting is unavailable", cause: nil
  end

  def self.key(site:, email:)
    identity = [Rails.env, Folio::User.connection_db_config.database, site.id, email.to_s.strip.downcase].join("\0")
    "folio:email_login:delivery:#{Digest::SHA256.hexdigest(identity)}"
  end

  def self.redis
    @redis ||= Redis.new(url: redis_url, connect_timeout: 1, read_timeout: 1, write_timeout: 1, reconnect_attempts: 1)
  end

  def self.redis_url
    ENV.fetch("REDIS_URL", "redis://localhost:6379/0")
  end
end
