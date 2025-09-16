# frozen_string_literal: true

class Folio::Console::Ui::TurboFrameWithLoaderComponent < Folio::Console::ApplicationComponent
  bem_class_name :loader_offset

  def initialize(id:,
                 disabled: false,
                 min_height: nil,
                 turbo_action: nil,
                 src: nil,
                 lazy: false,
                 loader_offset: true)
    @id = id
    @disabled = disabled
    @min_height = min_height
    @turbo_action = turbo_action
    @src = src
    @lazy = lazy
    @loader_offset = loader_offset
  end

  private
    def style
      if @min_height
        "min-height: #{@min_height};"
      end
    end
end
