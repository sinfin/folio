# frozen_string_literal: true

module Folio
  module CraMediaCloud
    class JobResolver
      STATUS_MAP = {
        "WAITING" => :processing,
        "PROCESSING" => :processing,
        "CREATED" => :processing,
        "VALIDATING" => :processing,
        "DONE" => :done,
        "FAILED" => :failed,
        "ERROR" => :failed,
        "REMOVED" => :not_found,
      }.freeze

      def self.resolve(jobs)
        return { status: :not_found, job: nil } if jobs.empty?

        job = latest_job(jobs)
        status = STATUS_MAP[job["status"]] || :not_found
        { status:, job: }
      end

      def self.latest_job(jobs)
        return nil if jobs.empty?
        jobs.max_by { |j| Time.parse(j["lastModified"]) }
      end

      private_class_method :latest_job
    end
  end
end
