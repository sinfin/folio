# frozen_string_literal: true

class Folio::Console::Layout::AuditedBarCell < Folio::ConsoleCell
  def show
    render if model.present?
  end

  def restore_link
    link_to(t('.restore'),
            '#foo',
            method: :post,
            'data-confirm' => t('folio.console.confirmation'),
            class: 'btn btn-secondary font-weight-bold mr-g my-1')
  end
end
