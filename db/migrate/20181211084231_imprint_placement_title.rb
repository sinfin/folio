class ImprintPlacementTitle < ActiveRecord::Migration[5.2]
  def change
    add_column :folio_file_placements, :placement_title, :string
    add_column :folio_file_placements, :placement_title_type, :string

    Folio::FilePlacement::Base.find_each do |fp|
      fp.send(:extract_placement_title_and_type)
    end
  end
end
