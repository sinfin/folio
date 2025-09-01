# frozen_string_literal: true

class Folio::Console::Ui::TurboFrameWithLoaderComponent < Folio::Console::ApplicationComponent
  def initialize(id:, disabled: false, min_height: nil, turbo_action: nil, src: nil)
    @id = id
    @disabled = disabled
    @min_height = min_height
    @turbo_action = turbo_action
    @src = src
  end

  private
    def style
      if @min_height
        "min-height: #{@min_height};"
      end
    end
end
