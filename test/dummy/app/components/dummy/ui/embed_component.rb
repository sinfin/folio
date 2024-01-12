# frozen_string_literal: true

class Dummy::Ui::EmbedComponent < ApplicationComponent
  def initialize(html:, caption: nil)
    @html = html
    @caption = caption
  end
end
