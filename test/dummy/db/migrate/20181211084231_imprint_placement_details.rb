class ImprintPlacementDetails < ActiveRecord::Migration[5.2]
  def change
    add_column :folio_file_placements, :placement_title, :string

    Folio::FilePlacement::Base.find_each do |file_placement|
      placement = file_placement.placement
      title = placement.try(:to_label) ||
              placement.try(:title) ||
              placement.try(:name)
      next if title.blank?
      file_placement.update_column(:placement_title, title)
    end
  end
end
