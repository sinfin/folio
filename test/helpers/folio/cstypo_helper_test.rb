# frozen_string_literal: true

require 'test_helper'

module Folio
  class CstypoHelperTest < ActiveSupport::TestCase
    include CstypoHelper

    test 'works for cs' do
      I18n.with_locale(:cs) do
        assert_equal('Zdá vyšších ruky <a href="#">toto</a> David listu, činná <b>ruském</b> byly zda ilustrační, šimpanzí k&nbsp;zimu vy míst já budou s&nbsp;z&nbsp;špatného likvidaci.',
                     cstypo('Zdá vyšších ruky <a href="#">toto</a> David listu, činná <b>ruském</b> byly zda ilustrační, šimpanzí k zimu vy míst já budou s z špatného likvidaci.'))
      end
    end

    test 'works for en' do
      I18n.with_locale(:en) do
        assert_equal('Zdá vyšších ruky toto David listu, činná ruském byly zda ilustrační, šimpanzí k zimu vy míst já budou s z špatného likvidaci.',
                     cstypo('Zdá vyšších ruky toto David listu, činná ruském byly zda ilustrační, šimpanzí k zimu vy míst já budou s z špatného likvidaci.'))
      end
    end
  end
end
