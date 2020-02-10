# frozen_string_literal: true

require 'test_helper'

class Folio::CstypoHelperTest < ActiveSupport::TestCase
  include Folio::CstypoHelper

  test 'works for cs' do
    I18n.with_locale(:cs) do
      assert_equal('Zdá vyšších ruky <a href="#">toto</a> David listu, činná <b>ruském</b> byly zda ilustrační, šimpanzí za 3&nbsp;000&nbsp;Kč k&nbsp;zimu vy míst já budou s&nbsp;z&nbsp;špatného likvidaci.',
                   cstypo('Zdá vyšších ruky <a href="#">toto</a> David listu, činná <b>ruském</b> byly zda ilustrační, šimpanzí za 3 000 Kč k zimu vy míst já budou s z špatného likvidaci.'))
    end
  end

  test 'works for en' do
    I18n.with_locale(:en) do
      assert_equal('Zdá vyšších ruky toto David listu, činná ruském byly zda ilustrační, šimpanzí za 3 000 Kč k zimu vy míst já budou s z špatného likvidaci.',
                   cstypo('Zdá vyšších ruky toto David listu, činná ruském byly zda ilustrační, šimpanzí za 3 000 Kč k zimu vy míst já budou s z špatného likvidaci.'))
    end
  end
end
