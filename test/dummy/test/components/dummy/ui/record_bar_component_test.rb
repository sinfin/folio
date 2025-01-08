# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::RecordBarComponentTest < Folio::ComponentTest
  def test_render
    site = get_any_site
    user = create(:folio_user, :superadmin)
    record = create(:folio_page)

    Folio::Current.ability = Folio::Ability.new(user, site)

    render_inline(Dummy::Ui::RecordBarComponent.new(record:))
    assert_selector(".d-ui-record-bar")
  end

  def test_render_no_record
    render_inline(Dummy::Ui::RecordBarComponent.new(record: nil))
    assert_no_selector(".d-ui-record-bar")
  end

  def test_render_no_user
    record = create(:folio_page)

    render_inline(Dummy::Ui::RecordBarComponent.new(record:))
    assert_no_selector(".d-ui-record-bar")
  end
end
