# frozen_string_literal: true

require 'test_helper'

class Console::AtomFormFieldsCellTest < Cell::TestCase
  test 'show' do
    html = cell('atom_form_fields').(:show)
    assert html.match /<p>/
  end
end
