# frozen_string_literal: true

class Dummy::Atom::TwoColumnsTextComponent < ApplicationComponent
  bem_class_name :background, :two_columns_on_mobile

  def initialize(atom:, atom_options: {})
    @atom = atom
    @atom_options = atom_options
    @background = @atom.wrapper == "background"
    @dark_mode = @atom.color_mode == "dark"
    @two_columns_on_mobile = @atom.mobile_layout == "two"
  end

  def inner_narrow_container_tag
    h = {
      tag: :div,
      class: "container-fluid container-fluid--forced-padding container-narrow"
    }

    h
  end
end
