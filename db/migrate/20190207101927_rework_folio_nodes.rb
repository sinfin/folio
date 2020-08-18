# frozen_string_literal: true

class ReworkFolioNodes < ActiveRecord::Migration[5.2]
  def change
    # rename table
    rename_table :folio_nodes, :folio_pages

    # fix types
    conn = ActiveRecord::Base.connection
    conn.execute <<~SQL
      UPDATE folio_pages
      SET
        type = 'Folio::Page'
      WHERE
        type IN ('Folio::Node', 'Folio::Category', 'Folio::NodeTranslation')
    SQL

    conn.execute <<~SQL
      UPDATE folio_menu_items
      SET
        target_type = 'Folio::Page'
      WHERE
        target_type IN ('Folio::Node', 'Folio::Category', 'Folio::NodeTranslation')
    SQL

    conn.execute <<~SQL
      UPDATE folio_atoms
      SET
        placement_type = 'Folio::Page'
      WHERE
        placement_type IN ('Folio::Node', 'Folio::Category', 'Folio::NodeTranslation')
    SQL

    [
      ["folio_atoms", "placement_type"],
      ["folio_atoms", "model_type"],
      ["folio_file_placements", "placement_type"],
      ["folio_menu_items", "target_type"],
      ["friendly_id_slugs", "sluggable_type"],
      ["pg_search_documents", "searchable_type"],
      ["taggings", "taggable_type"],
    ].each do |table, col|
      conn.execute <<~SQL
        UPDATE #{table}
        SET
          #{col} = 'Folio::Page'
        WHERE
          #{col} IN ('Folio::Node', 'Folio::Category', 'Folio::NodeTranslation')
      SQL
    end

    # correct Folio::NodeTranslation type
    Folio::Page.where.not(original_id: nil).find_each do |page|
      page.update_column(:type, page.original.type)
    end

    # convert content to Text atoms
    columns = Folio::Page.column_names.grep(/content.*/)

    puts "Converting node contents to atoms"

    Folio::Page.find_each do |node|
      if node.try(:content).present? || node.try("content_#{I18n.default_locale}").present?
        values = {}

        columns.each do |col|
          if node.send(col).present?
            values[col] = node.send(col)
          end
        end

        if values.blank?
          print "-"
          next
        end

        atom = Folio::Atom::Text.new(values.merge(placement: node,
                                                  position: -1))
        if atom.save(validate: false)
          print "."
        else
          print "x"
        end
      end
    end

    columns.each { |col| remove_column :folio_pages, col }
    remove_column :folio_pages, :code
  end
end
