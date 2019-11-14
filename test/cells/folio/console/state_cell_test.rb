# frozen_string_literal: true

require 'test_helper'

class Folio::Console::StateCellTest < Folio::Console::CellTest
  test 'show' do
    I18n.with_locale(:en) do
      lead = create(:folio_lead)
      html = cell('folio/console/state', lead).(:show)
      assert_equal('To be handled', html.find('.dropdown-toggle').text)
      assert_equal('Handle', html.find('.dropdown-item').text)

      lead.handle!
      html = cell('folio/console/state', lead).(:show)
      assert_equal('Handled', html.find('.dropdown-toggle').text)
      assert_equal('Unhandle', html.find('.dropdown-item').text)
    end
  end
end
