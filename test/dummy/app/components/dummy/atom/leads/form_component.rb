# frozen_string_literal: true

class Dummy::Atom::Leads::FormComponent < ApplicationComponent
  def initialize(atom:, atom_options: {})
    @atom = atom
    @atom_options = atom_options
  end

  def lead_component
    Rails.application.config.folio_leads_from_component_class_name.constantize
  end
end
