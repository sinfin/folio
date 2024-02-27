# frozen_string_literal: true

module ActionMailerTestHelper
  def assert_mailer_job_enqueued(mailer, action)
    expected = { mailer:, action: }.compact
    jobs = enqueued_jobs

    matching_job = jobs.find do |enqueued_job|
      deserialized_job = deserialize_args_for_assertion(enqueued_job)

      deserialized_job["job_class"] == "ActionMailer::MailDeliveryJob" &&
        deserialized_job["arguments"][0] == mailer &&
        deserialized_job["arguments"][1] == action
    end

    message = +"No enqueued mailer jobs found with #{expected}"

    assert matching_job, message
    instantiate_job(matching_job)
  end
end
