# frozen_string_literal: true

require "test_helper"
require "timeout"

class Folio::Users::EmailLoginConcurrencyTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  def setup
    super
    @site = create_site(force: true)
    @user = create(:folio_user, auth_site: @site)
    @nonce = SecureRandom.hex(32)
    @challenge, @token = Folio::Devise::EmailLogin::IssueChallenge.call(user: @user, site: @site,
                                                                     nonce: @nonce, purpose: "password")
  end

  def teardown
    @user&.destroy!
    @site&.destroy!
    super
  end

  test "two database connections cannot consume the same approval" do
    @challenge.approve!(token: @token, site: @site)

    results = concurrently do
      challenge = Folio::Users::EmailLoginChallenge.find(@challenge.id)
      challenge.consume!(nonce: @nonce, site: @site)
      :consumed
    rescue Folio::Devise::EmailLogin::InvalidChallenge
      :rejected
    end

    assert_equal [:consumed, :rejected], results.sort
    assert_equal "consumed", @challenge.reload.state
  end

  test "completion and resend cannot both use the original approval" do
    @challenge.update!(created_at: 61.seconds.ago)
    @challenge.approve!(token: @token, site: @site)
    results = concurrently do |index|
      challenge = Folio::Users::EmailLoginChallenge.find(@challenge.id)
      if index.zero?
        Folio::Devise::EmailLogin::IssueChallenge.call(user: Folio::User.find(@user.id), site: @site,
                                                      nonce: @nonce, purpose: "password", previous: challenge)
        :resent
      else
        challenge.consume!(nonce: @nonce, site: @site)
        :consumed
      end
    rescue Folio::Devise::EmailLogin::InvalidChallenge
      :rejected
    end

    assert_includes [[:resent, :rejected], [:rejected, :consumed]], results
    assert_equal results.first == :resent ? "revoked" : "consumed", @challenge.reload.state
    assert_equal results.first == :resent ? 2 : 1, @user.email_login_challenges.count
  end

  test "revocation racing completion leaves no reusable proof" do
    @challenge.approve!(token: @token, site: @site)
    results = concurrently do |index|
      if index.zero?
        Folio::User.find(@user.id).revoke_email_login_verifications!
        :revoked
      else
        Folio::Users::EmailLoginChallenge.find(@challenge.id).consume!(nonce: @nonce, site: @site)
        :consumed
      end
    rescue Folio::Devise::EmailLogin::InvalidChallenge
      :rejected
    end

    assert_includes [[:revoked, :consumed], [:revoked, :rejected]], results
    challenge = Folio::Users::EmailLoginChallenge.find(@challenge.id)
    assert_not challenge.usable_for?(@site)
    assert_raises(Folio::Devise::EmailLogin::InvalidChallenge) { challenge.consume!(nonce: @nonce, site: @site) }
  end

  private
    def concurrently(&block)
      ready = Queue.new
      start = Queue.new
      threads = 2.times.map do |index|
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do |connection|
            ready << connection.raw_connection.backend_pid
            start.pop
            block.call(index)
          end
        end
      end

      Timeout.timeout(10) do
        connections = 2.times.map { ready.pop }
        assert_equal 2, connections.uniq.size, "the race must use independent PostgreSQL connections"
        2.times { start << true }
        threads.map(&:value)
      end
    ensure
      2.times { start << true }
      threads&.each do |thread|
        thread.kill unless thread.join(1)
      end
    end
end
