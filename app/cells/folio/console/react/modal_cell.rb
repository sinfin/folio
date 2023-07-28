# frozen_string_literal: true

class Folio::Console::React::ModalCell < Folio::ConsoleCell
  CLASS_NAME_BASE = "f-c-r-modal"
  CLASS_NAME = ".#{CLASS_NAME_BASE}"

  def show
    if ["new", "edit", "create", "update"].include?(controller.action_name) || controller.try(:force_use_react_modals?)
      cell("folio/console/modal",
           class: "#{CLASS_NAME_BASE} f-c-r-modal--with-scroll-wrap",
           body: render,
           title: t(".title/#{klass.human_type}", fallback: t(".title")),
           new_button: true,
           size: :react,
           data: { klass: model })
    end
  end

  def klass
    @klass ||= model.constantize
  end

  def data
    url = if options[:url_name]
      controller.main_app.send(options[:url_name])
    else
      url_for([:console, :api, klass])
    end

    {
      "file-type" => model,
      "files-url" => url,
      "react-type" => klass.human_type,
      "taggable" => klass.react_taggable ? "1" : nil,
      "mode" => "modal-single-select",
    }
  end
end
