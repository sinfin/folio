# frozen_string_literal: true

def get_subclasses(node)
  [node] + node.subclasses.map { |subclass| get_subclasses(subclass) }
end

module Folio
  module Console::AtomsHelper
    def atom_types_for_select
      (get_subclasses(Folio::Atom).flatten - [Folio::Atom]).map do |type|
        [t("atom_names.#{type}"), type]
      end
    end
  end
end
