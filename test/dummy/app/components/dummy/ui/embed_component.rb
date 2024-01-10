# frozen_string_literal: true

class Dummy::Ui::EmbedComponent < ApplicationComponent
  def initialize(embed:, caption: nil)
    @embed = embed
    @caption = caption
  end
end
