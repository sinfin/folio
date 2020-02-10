# frozen_string_literal: true

class Folio::Console::Merges::FormCell < Folio::ConsoleCell
  include SimpleForm::ActionViewExtensions::FormHelper
  include ActionView::Helpers::FormOptionsHelper

  def form(&block)
    opts = {
      url: controller.console_merge_path(model.klass,
                                         model.original,
                                         model.duplicate),
      html: { class: 'f-c-merges-form__form' },
      method: :post,
    }

    simple_form_for(model.original, opts, &block)
  end
end
