# frozen_string_literal: true

# This migration comes from acts_as_taggable_on_engine (originally 7)
class AddTenantToTaggings < ActiveRecord::Migration[6.0]
  def self.up
    add_column ActsAsTaggableOn.taggings_table, :tenant, :string, limit: 128
    add_index ActsAsTaggableOn.taggings_table, :tenant unless index_exists? ActsAsTaggableOn.taggings_table, :tenant

    # Sets tenant for all existing taggings with value from
    # taggable (Folio::File) that responds to site_id
    ActsAsTaggableOn::Tagging.reset_column_information
    ActsAsTaggableOn::Tagging.find_each do |tagging|
      if tagging.taggable.respond_to?(:site_id)
        unless Rails.application.config.folio_shared_files_between_sites && tagging.taggable.is_a?(Folio::File)
          tagging.update_column(:tenant, tagging.taggable.site_id)
        end
      end
    end
  end

  def self.down
    remove_index ActsAsTaggableOn.taggings_table, :tenant
    remove_column ActsAsTaggableOn.taggings_table, :tenant
  end
end
