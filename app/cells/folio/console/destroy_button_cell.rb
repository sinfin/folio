# frozen_string_literal: true

class Folio::Console::DestroyButtonCell < Folio::ConsoleCell
  def show
    button if model && model.persisted?
  end

  def button
    link_to(label, url, class: 'f-c-destroy-button btn btn-danger',
                        method: :delete,
                        'data-confirm': question)
  end

  def label
    t('folio.console.actions.destroy')
  end

  def url
    controller.url_for([:console, model])
  end

  def question
    t('folio.console.really_delete', title: model.to_label)
  end
end
