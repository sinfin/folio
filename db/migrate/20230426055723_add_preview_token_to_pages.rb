# frozen_string_literal: true

class AddPreviewTokenToPages < ActiveRecord::Migration[7.0]
  def change
    add_column :folio_pages, :preview_token, :string

    unless reverting?
      say_with_time "Setting page preview tokens" do
        Folio::Page.find_each(&:reset_preview_token!)
      end
    end
  end
end
