# frozen_string_literal: true

class AddRemoteKeysToFolioFiles < ActiveRecord::Migration[7.0]
  def change
    add_column :folio_files, :remote_services_data, :json, default: {}
  end
end
