# frozen_string_literal: true

class AddFileSensitiveContentBool < ActiveRecord::Migration[6.0]
  def change
    add_column :folio_files, :sensitive_content, :boolean, default: false
  end
end
