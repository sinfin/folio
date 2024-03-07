# frozen_string_literal: true

class Folio::Console::React::ModalComponent < Folio::Console::ApplicationComponent
  CLASS_NAME = "f-c-r-modal"

  def initialize(class_name:, url_name: nil)
    @class_name = class_name
    @klass = class_name.constantize
    @url_name = url_name
  end

  def render?
    %w[new edit create update].include?(controller.action_name) || controller.try(:force_use_react_modals?)
  end

  def title
    t(".title/#{@klass.human_type}", fallback: t(".title"))
  end

  def data
    url = if @url_name
      controller.main_app.send(@url_name)
    else
      url_for([:console, :api, @klass])
    end

    {
      "file-type" => @class_name,
      "files-url" => url,
      "react-type" => @klass.human_type,
      "taggable" => @klass.react_taggable ? "1" : nil,
      "mode" => "modal-single-select",
    }
  end
end
