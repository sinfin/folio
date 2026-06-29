# frozen_string_literal: true

# when shared files are enabled, this model restricts usage of specific file to specific sites
class Folio::MediaSourceSiteLink < ApplicationRecord
  belongs_to :media_source, class_name: "Folio::MediaSource"
  belongs_to :site, class_name: "Folio::Site"

  validates :media_source_id, uniqueness: { scope: :site_id }
  validates :max_usage_count, numericality: { greater_than: 0, allow_nil: true }

  def effective_max_usage_count
    max_usage_count.presence || media_source.max_usage_count
  end
end
