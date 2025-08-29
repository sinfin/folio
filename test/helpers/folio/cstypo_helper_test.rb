# frozen_string_literal: true

require "test_helper"

class Folio::CstypoHelperTest < ActiveSupport::TestCase
  include Folio::CstypoHelper

  test "works for cs" do
    I18n.with_locale(:cs) do
      result = cstypo('Zdá vyšších ruky <a href="#">toto</a> David listu, činná <b>byly zda</b> ilustrační, šimpanzí za 3 000 Kč k zimu vy míst já budou s z špatného likvidaci.')
      assert_not result.html_safe?
      assert_equal('Zdá vyšších ruky <a href="#">toto</a> David listu, činná <b>byly zda</b> ilustrační, šimpanzí za 3 000 Kč k zimu vy míst já budou s z špatného likvidaci.',
                   result)

      result = cstypo("Za 3 000 Kč\nk zimu")
      assert_not result.html_safe?
      assert_equal("Za 3 000 Kč\nk zimu",
                   result)

      result = cstypo("Za 3 000 Kč\nk zimu")
      assert_not result.html_safe?
      assert_equal("Za 3 000 Kč\nk zimu",
                   result)
    end
  end

  test "works for en" do
    I18n.with_locale(:en) do
      result = cstypo("Zdá vyšších ruky toto David listu, činná byly zda ilustrační, šimpanzí za 3 000 Kč k zimu vy míst já budou s z špatného likvidaci.")
      assert_not result.html_safe?
      assert_equal("Zdá vyšších ruky toto David listu, činná byly zda ilustrační, šimpanzí za 3 000 Kč k zimu vy míst já budou s z špatného likvidaci.",
                   result)

      result = cstypo("Za 3 000 Kč\nk zimu")
      assert_not result.html_safe?
      assert_equal("Za 3 000 Kč\nk zimu",
                   result)

      result = cstypo("Za 3 000 Kč\nk zimu")
      assert_not result.html_safe?
      assert_equal("Za 3 000 Kč\nk zimu",
                   result)
    end
  end
end
