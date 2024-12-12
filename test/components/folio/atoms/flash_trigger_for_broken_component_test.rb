# frozen_string_literal: true

require "test_helper"

class Folio::Atoms::FlashTriggerForBrokenComponentTest < Folio::ComponentTest
  def test_render
    site = get_any_site
    user = create(:folio_user, :superadmin)
    record = create(:folio_page)

    Folio::Current.ability = Folio::Ability.new(user, site)

    error = StandardError.new("test")

    broken_atoms_data = [
      { atom: create_atom(Dummy::Atom::Contents::Text, :content), error: }
    ]

    render_inline(Folio::Atoms::FlashTriggerForBrokenComponent.new(record:,
                                                                   broken_atoms_data:))

    assert_selector(".f-atoms-flash-trigger-for-broken", visible: false)
  end

  def test_blank
    render_inline(Folio::Atoms::FlashTriggerForBrokenComponent.new)

    assert_no_selector(".f-atoms-flash-trigger-for-broken", visible: false)
  end
end
