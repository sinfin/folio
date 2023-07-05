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
    url = url_for([:console, :api, klass])

    {
      "file-type" => model,
      "files-url" => url,
      "react-type" => klass.human_type,
      "taggable" => klass.react_taggable ? "1" : nil,
      "mode" => "modal-single-select",
    }
  end
end

#   .modal.f-c-r-modal.f-c-r-modal--with-scroll-wrap.fade data-klass=class_name
#     .modal-dialog.modal-lg.f-c-r-modal__modal-dialog
#       .modal-content.f-c-r-modal__modal-content
#         .modal-body.f-c-r-modal__modal-body
#           = react_modal_for(class_name)

#           button type="button" class="close" data-dismiss="modal" &times;

# end
