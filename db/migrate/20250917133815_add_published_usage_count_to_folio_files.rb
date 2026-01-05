# frozen_string_literal: true

class AddPublishedUsageCountToFolioFiles < ActiveRecord::Migration[8.0]
  def change
    add_column :folio_files, :published_usage_count, :integer, default: 0, null: false
    add_index :folio_files, :published_usage_count

    # Run rake folio:developer_tools:calculate_file_published_usage_counts to populate values
    # Values will be updated automatically when placements change or objects are published/unpublished
  end
end
