# frozen_string_literal: true

class Folio::Console::FormFooterCell < Folio::ConsoleCell
  def class_name
    'folio-console-form-footer--static' if options[:static]
  end

  def delete_button
    name = model.object.try(:to_label) || model.object.try(:title)
    question = t('folio.console.really_delete', title: name)

    link_to(t('folio.console.breadcrumbs.actions.delete'),
            options[:destroy],
            'data-confirm': question,
            method: :delete,
            class: 'btn btn-danger')
  end
end
