# frozen_string_literal: true

class Folio::FileSiteLink < Folio::ApplicationRecord
  belongs_to :file, class_name: "Folio::File", foreign_key: :file_id
  belongs_to :site, class_name: "Folio::Site", foreign_key: :site_id

  validates :file_id, uniqueness: { scope: :site_id }
end
