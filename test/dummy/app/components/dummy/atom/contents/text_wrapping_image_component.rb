# frozen_string_literal: true

class Dummy::Atom::Contents::TextWrappingImageComponent < ApplicationComponent
  THUMB_SIZES = {
    "origin" => "368x",
    "1x1" => "368x368#",
    "3x2" => "368x245#",
    "16x9" => "368x207#",
    "4x3" => "368x276#",
    "2x3" => "320x552#",
    "9x16" => "270x654#",
    "3x4" => "360x491#",
  }

  def initialize(atom:, atom_options: {})
    @atom = atom
    @atom_options = atom_options
  end

  def atom_class_name
    ary = []
    base = "d-atom-contents-text-wrapping-image"

    ary << base
    ary << "#{base}--image-#{@atom.image_side_with_fallback}"
    ary << "#{base}--theme-#{@atom.theme_with_fallback}"

    ary << "#{base}--highlight-#{@atom.highlight}" if @atom.highlight

    ary.join(" ")
  end

  def image_wrap_class
    base = "d-atom-contents-text-wrapping-image__image-wrap"

    "#{base} #{base}--ratio-#{@atom.cover_ratio_with_fallback}"
  end

  def cover_thumb_size
    THUMB_SIZES[@atom.cover_ratio_with_fallback]
  end
end
