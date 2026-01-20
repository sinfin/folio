# frozen_string_literal: true

class Folio::Cache::ExpireJob < Folio::ApplicationJob
  queue_as :default

  # activejob-uniqueness prevents duplicate jobs
  unique :until_executed, on_conflict: :log

  def perform(site_id:, key:)
    Folio::Cache::Invalidator.invalidate!(site_id:, keys: [key])
  end
end
