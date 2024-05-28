# frozen_string_literal: true

class Dummy::Atom::TextAroundVideoComponent < ApplicationComponent
  def initialize(atom:, atom_options: {})
    @atom = atom
    @atom_options = atom_options
  end

  def atom_class_name
    ary = []
    base = "d-atom-text-around-video"

    ary << base
    ary << "#{base}--video-#{@atom.video_side_with_fallback}"
    ary << "#{base}--theme-#{@atom.theme_with_fallback}"

    ary << "#{base}--highlight-#{@atom.highlight}" if @atom.highlight

    ary.join(" ")
  end

  def video_component
    Dummy::Ui::VideoComponent.new(video: @atom.video_cover_placement.file,
                                  aspect_ratio:)
  end

  def aspect_ratio
    @atom.video_aspect_ratio.presence
  end
end
