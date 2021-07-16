# frozen_string_literal: true

class AddAncestrySlugsToPages < ActiveRecord::Migration[6.0]
  def change
    add_column :folio_pages, :ancestry_slug, :string


    unless reverting?
      Folio::Page.where.not(ancestry: nil).each do |page|
        parts = []
        runner = page

        while runner = runner.parent
          parts << runner
        end

        ancestry_slug = parts.reverse.map(&:slug).join("/")

        page.update_column(:ancestry_slug, ancestry_slug)
      end
    end
  end
end
