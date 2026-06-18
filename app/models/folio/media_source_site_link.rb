# frozen_string_literal: true

# when shared files are enabled, this model restricts usage of specific file to specific sites
class Folio::MediaSourceSiteLink < ApplicationRecord
  belongs_to :media_source, class_name: "Folio::MediaSource"
  belongs_to :site, class_name: "Folio::Site"

  validates :media_source_id, uniqueness: { scope: :site_id }
end
