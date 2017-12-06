# frozen_string_literal: true

def get_subclasses(node)
  [node] + node.subclasses.map { |subclass| get_subclasses(subclass) }
end

module Folio
  module Console::AtomsHelper
    def atom_types_for_select
      for_select = []
      get_subclasses(Folio::Atom).flatten.each do |type|
        for_select << [t("atom_names.#{type}"), type, { 'data-form' => type.form }] if type.form
      end
      for_select
    end

    def atom_model_collection_for_select(atom)
      atom.resource_for_select.map do |model|
        [
          model.to_label,
          model.id,
          { 'data-content': model.to_content }
        ]
      end
    end
  end
end
