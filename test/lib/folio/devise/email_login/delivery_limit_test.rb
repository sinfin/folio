# frozen_string_literal: true

require "test_helper"

class Folio::Devise::EmailLogin::DeliveryLimitTest < ActiveSupport::TestCase
  def setup
    super
    travel_to Time.current
    @site = create_site(force: true)
    @email = "limit-#{SecureRandom.hex(8)}@example.test"
    @limiter = Folio::Devise::EmailLogin::DeliveryLimit
    @key = @limiter.key(site: @site, email: @email)
  end

  def teardown
    @limiter.redis.del(@key)
    super
  end

  test "cooldown and rolling window apply to normalized addresses without user records" do
    assert_no_difference("Folio::User.count") { consume }
    error = assert_raises(Folio::Devise::EmailLogin::Throttled) { consume(email: " #{@email.upcase} ") }
    assert_equal 60, error.retry_after
    2.times do
      travel 60.seconds
      consume
    end
    travel 60.seconds
    error = assert_raises(Folio::Devise::EmailLogin::Throttled) { consume }
    assert_equal 720, error.retry_after
    assert_operator @limiter.redis.ttl(@key), :>, 0

    travel 720.seconds
    consume
    assert_equal 3, @limiter.redis.zcard(@key)
  end

  test "two Redis connections cannot pass the cooldown together" do
    connections = 2.times.map { Redis.new(url: @limiter.redis_url) }
    assert_equal 2, connections.map { |connection| connection.client(:id) }.uniq.size
    ready = Queue.new
    start = Queue.new
    results = @limiter.stub(:redis, -> { Thread.current[:email_login_test_redis] }) do
      threads = connections.map do |connection|
        Thread.new do
          Thread.current[:email_login_test_redis] = connection
          ready << true
          start.pop
          consume
          :accepted
        rescue Folio::Devise::EmailLogin::Throttled
          :throttled
        end
      end
      2.times { ready.pop }
      2.times { start << true }
      threads.map(&:value)
    end
    assert_equal [:accepted, :throttled], results.sort
  ensure
    connections&.each(&:close)
  end

  private
    def consume(email: @email)
      @limiter.consume!(site: @site, email:)
    end
end
