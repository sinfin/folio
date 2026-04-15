# frozen_string_literal: true

class Folio::SpecialCharacters::ApplicationComponent < Folio::ApplicationComponent
  private
    def before_render
      @stimulus_controller_name = "f-special-characters-popup"
      super
    end
end
