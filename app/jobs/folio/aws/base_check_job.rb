# frozen_string_literal: true

class Folio::Aws::BaseCheckJob < Folio::ApplicationJob
  include Folio::S3::Client

  class << self
    attr_reader :interval, :max

    # Set interval and maximum retries
    # By default 1 minute with 5 sec interval
    # @param [Integer] interval Interval in seconds
    # @param [Integer] max Maximum retries until it stops
    def retries(interval: 5, max: 12)
      @interval = interval
      @max = max
    end
  end

  queue_as :default

  def perform(file_type, file_uuid, counter = 0)
    return if counter >= self.class.max

    file = file_type.find_by(file_uuid: file_uuid)

    return unless file

    return if do_check(file)

    self.class.set(wait: self.class.interval.seconds).perform_later(file_type, file_uuid, counter + 1)
  end

  def do_check(file)
    raise StandardError, "Must be implemented in child class"
  end
end
