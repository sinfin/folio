# frozen_string_literal: true

class Folio::SpecialCharacters::ListComponent < Folio::ApplicationComponent
  def initialize(stimulus_controller_name:)
    @stimulus_controller_name = stimulus_controller_name
  end

  def self.character_string
    Rails.application.config.folio_special_characters_character_string
  end

  private
    def characters
      self.class.character_string.grapheme_clusters
    end

    def char_data(ch)
      if @stimulus_controller_name
        stimulus_action(click: "insertCharacter").merge(char: ch)
      end
    end
end
