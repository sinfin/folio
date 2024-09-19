# frozen_string_literal: true

class Dummy::Atom::Embed::HtmlComponent < ApplicationComponent
  def initialize(atom:, atom_options: {})
    @atom = atom
    @atom_options = atom_options
  end
end
