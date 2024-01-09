# frozen_string_literal: true

class Dummy::Ui::EmbedComponent < ApplicationComponent
  def initialize(embed:, caption:)
    @embed = embed
    @caption = caption
  end
end
