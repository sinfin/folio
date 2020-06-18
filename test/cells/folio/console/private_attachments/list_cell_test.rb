# frozen_string_literal: true

require 'test_helper'

class Folio::Console::PrivateAttachments::ListCellTest < Folio::Console::CellTest
  test 'show' do
    html = cell('folio/console/private_attachments/list', []).(:show)
    assert html.has_css?('.f-c-private-attachments-list .text-muted')

    pas = create_list(:folio_private_attachment, 1)
    html = cell('folio/console/private_attachments/list', pas).(:show)
    assert html.has_css?('.f-c-private-attachments-list .f-c-private-attachments-list__a')
  end
end
