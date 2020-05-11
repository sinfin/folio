# frozen_string_literal: true

class ConvertAtomFieldsToJson < ActiveRecord::Migration[5.2]
  def change
    add_column :folio_atoms, :data, :jsonb, default: {}
    add_column :folio_atoms, :associations, :jsonb, default: {}

    Folio::Atom::Base.find_each do |atom|
      data = {
        title: atom.title,
        perex: atom.perex,
        content: atom.content,
      }

      associations = {}
      if atom.model_type && atom.model_id
        associations[:model] = {
          type: atom.model_type,
          id: atom.model_id,
        }
      end

      atom.update_columns(data: data,
                          associations: associations)
    end

    remove_column :folio_atoms, :title, :string
    remove_column :folio_atoms, :perex, :text
    remove_column :folio_atoms, :content, :text
    remove_reference :folio_atoms, :model, polymorphic: true
  end
end
