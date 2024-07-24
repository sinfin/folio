# frozen_string_literal: true

class Dummy::Atom::TitleComponent < ApplicationComponent
  def initialize(atom:, atom_options: {})
    @atom = atom
    @atom_options = atom_options
  end

  def adaptive_font_size?
    @atom.font_size == "adaptive"
  end

  def atom_class_name
    ary = []
    base = "d-atom-title"

    ary << base
    ary << "#{base}--align-#{@atom.alignment_with_fallback}"
    ary << "#{base}--theme-#{@atom.theme_with_fallback}"

    ary << "#{base}--highlight-#{@atom.highlight}" if @atom.highlight
    ary << "#{base}--font-size-#{@atom.font_size_with_fallback}" if adaptive_font_size?

    ary.join(" ")
  end

  def title_tag
    base = "d-atom-title__title"

    {
      tag: @atom.tag_with_fallback,
      class: [base, font_size_class_name(base)].compact.join(" "),
    }
  end

  def font_size_class_name(base)
    return unless adaptive_font_size?
    adaptive_font_size_class_name(@atom.title) if @atom.title.present?
  end

  def rich_text_chomp_class
    "d-rich-text--chomp" if @atom.highlight
  end
end
