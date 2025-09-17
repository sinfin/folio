# frozen_string_literal: true

class Folio::FileSiteLink < Folio::ApplicationRecord
  belongs_to :file, class_name: "Folio::File", foreign_key: :file_id
  belongs_to :site, class_name: "Folio::Site", foreign_key: :site_id

  validates :file_id, uniqueness: { scope: :site_id }
end

# == Schema Information
#
# Table name: folio_file_site_links
#
#  id         :bigint(8)        not null, primary key
#  file_id    :bigint(8)        not null
#  site_id    :bigint(8)        not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_folio_file_site_links_on_file_id  (file_id)
#  index_folio_file_site_links_on_site_id  (site_id)
#  index_folio_file_site_links_unique      (file_id,site_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (file_id => folio_files.id)
#  fk_rails_...  (site_id => folio_sites.id)
#
