require 'test_helper'

class LeadFormCellTest < Cell::TestCase
  test 'show' do
    html = cell('folio/lead_form').(:show)
    assert html.has_css?('form')

    html = cell('folio/lead_form',
                build(:lead, email: 'a')).(:show)
    assert html.has_css?('form')
  end

  test 'shows success message' do
    html = cell('folio/lead_form', create(:lead)).(:show)
    assert html.has_css?('.folio-lead-form-submitted')
  end

  test 'shows note from option' do
    html = cell('folio/lead_form', nil, note: 'foo').(:show)
    assert_equal 'foo', html.find_css_selector('textarea').value
  end
end
