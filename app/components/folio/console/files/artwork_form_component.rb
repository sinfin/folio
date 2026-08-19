# frozen_string_literal: true

class Folio::Console::Files::ArtworkFormComponent < Folio::Console::ApplicationComponent
  def initialize(file:)
    @file = file
  end

  def render?
    @file.respond_to?(:artwork_cover_placement)
  end

  def soft_warnings
    placement = @file.artwork_cover_placement
    return [] if placement.blank? || placement.file.blank?

    warnings = placement.console_warnings
    return [] if warnings.blank?

    [{ file: placement.file, warnings: }]
  end
end
