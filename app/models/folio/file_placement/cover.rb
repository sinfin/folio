# frozen_string_literal: true

class Folio::FilePlacement::Cover < Folio::FilePlacement::Base
  include Folio::Sitemap::FilePlacement::Image

  folio_image_placement :cover_placement
end

# == Schema Information
#
# Table name: folio_file_placements
#
#  id                   :bigint(8)        not null, primary key
#  placement_type       :string
#  placement_id         :bigint(8)
#  file_id              :bigint(8)
#  position             :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  type                 :string
#  title                :text
#  alt                  :string
#  placement_title      :string
#  placement_title_type :string
#  description          :text
#
# Indexes
#
#  index_folio_file_placements_on_file_id                          (file_id)
#  index_folio_file_placements_on_placement_title                  (placement_title)
#  index_folio_file_placements_on_placement_title_type             (placement_title_type)
#  index_folio_file_placements_on_placement_type_and_placement_id  (placement_type,placement_id)
#  index_folio_file_placements_on_type                             (type)
#
