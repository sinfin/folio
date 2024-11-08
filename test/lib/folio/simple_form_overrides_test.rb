# frozen_string_literal: true

require "test_helper"

class Folio::SimpleFormOverridesTest < ActionView::TestCase
  include SimpleForm::ActionViewExtensions::FormHelper

  test "required: :published" do
    I18n.with_locale(:cs) do
      html = simple_form_for "", method: :get, url: "/" do |f|
        concat(f.input :required, required: true)
        concat(f.input :required_for_publishing, required: :published)
      end

      page = Capybara.string(html)

      assert page.has_css?(".form-control.required[name='required']", count: 1)
      assert page.has_css?(".form-control.required--published[name='required_for_publishing']", count: 1)

      assert page.has_css?(".form-label__required", count: 2)

      assert_equal "povinné pro uložení", page.find(".form-group._required .form-label__required")["data-f-tooltip-title-value"]
      assert_equal "povinné pro publikování", page.find(".form-group._required_for_publishing .form-label__required")["data-f-tooltip-title-value"]
    end
  end
end
