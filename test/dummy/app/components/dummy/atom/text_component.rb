# frozen_string_literal: true

class Dummy::Atom::TextComponent < ApplicationComponent
  def initialize(atom:, atom_options: {})
    @atom = atom
    @atom_options = atom_options
  end

  def atom_class_name
    ary = []
    base = "d-atom-text"

    ary << base
    ary << "#{base}--align-#{@atom.alignment_with_fallback}"
    ary << "#{base}--theme-#{@atom.theme_with_fallback}"

    ary << "#{base}--outline #{base}--outline-#{@atom.outline}" if @atom.outline.present?

    ary << "#{base}--highlight-#{@atom.highlight}" if @atom.highlight.present?

    ary.join(" ")
  end

  def rich_text_chomp_class
    "d-rich-text--chomp" if @atom.highlight.present? || @atom.outline.present?
  end
end
