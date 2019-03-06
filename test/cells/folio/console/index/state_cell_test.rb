# frozen_string_literal: true

require 'test_helper'

class Folio::Console::Index::StateCellTest < Folio::Console::CellTest
  test 'show' do
    I18n.with_locale(:en) do
      lead = create(:folio_lead)
      html = cell('folio/console/index/state', lead).(:show)
      assert_equal('To be handled', html.text)

      lead.handle!
      html = cell('folio/console/index/state', lead).(:show)
      assert_equal('Handled', html.text)
    end
  end
end
