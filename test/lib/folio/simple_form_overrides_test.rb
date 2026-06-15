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

      assert_equal "povinné pro uložení",
                   page.find(".form-group._required .form-label__required")["data-f-tooltip-title-value"]
      assert_equal "povinné pro publikování",
                   page.find(".form-group._required_for_publishing .form-label__required")["data-f-tooltip-title-value"]
    end
  end

  test "character counter string input marks wrapper" do
    html = simple_form_for "", method: :get, url: "/" do |f|
      concat(f.input :title, character_counter: true, wrapper_html: { class: "custom-form-group" })
    end

    page = Capybara.string(html)
    wrapper = page.find(".form-group._title")
    input = wrapper.find("input[name='title']")

    assert_includes wrapper["class"].split, "custom-form-group"
    assert_includes wrapper["class"].split, "form-group--with-character-counter"
    assert_includes input["data-controller"].split, "f-input-character-counter"
    assert_includes input["data-action"].split, "input->f-input-character-counter#onInput"
    assert_includes input["data-action"].split, "change->f-input-character-counter#onInput"
  end

  test "character counter text input marks wrapper and max value" do
    html = simple_form_for "", method: :get, url: "/" do |f|
      concat(f.input :intro, as: :text, character_counter: 160)
    end

    page = Capybara.string(html)
    wrapper = page.find(".form-group._intro")
    input = wrapper.find("textarea[name='intro']")

    assert_includes wrapper["class"].split, "form-group--with-character-counter"
    assert_includes input["data-controller"].split, "f-input-character-counter"
    assert_equal "160", input["data-f-input-character-counter-max-value"]
  end

  test "url json input renders custom html before hint" do
    html = simple_form_for "", method: :get, url: "/" do |f|
      concat(f.input :link_json, as: :url_json, hint: "Visible hint")
    end

    page = Capybara.string(html)

    assert page.has_css?(".form-group._link_json .form-group__custom-html", count: 1)
    assert page.has_css?(".form-group._link_json .form-group__custom-html + .form-text", text: "Visible hint")
  end
end
