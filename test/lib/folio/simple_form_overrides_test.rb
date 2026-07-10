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

  test "character counter preserves existing nested input data" do
    html = simple_form_for "", method: :get, url: "/" do |f|
      concat(f.input :title,
                     character_counter: true,
                     input_html: {
                       data: {
                         action: "input->host-controller#onInput",
                         key: "title_google",
                       },
                     })
    end

    input = Capybara.string(html).find("input[name='title']")

    assert_equal "title_google", input["data-key"]
    assert_includes input["data-action"].split, "input->host-controller#onInput"
    assert_includes input["data-action"].split, "input->f-input-character-counter#onInput"
    assert_includes input["data-action"].split, "change->f-input-character-counter#onInput"
  end

  test "character counter text input marks wrapper, max value and automatic current count limit" do
    html = simple_form_for "", method: :get, url: "/" do |f|
      concat(f.input :intro, as: :text, character_counter: 160)
    end

    page = Capybara.string(html)
    wrapper = page.find(".form-group._intro")
    input = wrapper.find("textarea[name='intro']")

    assert_includes wrapper["class"].split, "form-group--with-character-counter"
    assert_includes input["data-controller"].split, "f-input-character-counter"
    assert_equal "160", input["data-f-input-character-counter-max-value"]
    assert_equal "999", input["data-f-input-character-counter-current-count-limit-value"]
  end

  test "character counter automatic current count limit can be disabled" do
    html = simple_form_for "", method: :get, url: "/" do |f|
      concat(f.input :intro,
                     as: :text,
                     character_counter: 160,
                     character_counter_auto_current_count_limit: false)
    end

    page = Capybara.string(html)
    wrapper = page.find(".form-group._intro")
    input = wrapper.find("textarea[name='intro']")

    assert_equal "160", input["data-f-input-character-counter-max-value"]
    assert_nil input["data-f-input-character-counter-current-count-limit-value"]
  end

  test "url json input renders custom html before hint" do
    html = simple_form_for "", method: :get, url: "/" do |f|
      concat(f.input :link_json, as: :url_json, hint: "Visible hint")
    end

    page = Capybara.string(html)

    assert page.has_css?(".form-group._link_json .form-group__custom-html", count: 1)
    assert page.has_css?(".form-group._link_json .form-group__custom-html + .form-text", text: "Visible hint")
  end

  test "filterable collection select preserves grouped collection" do
    grouped_collection = [
      ["Project B", [["Beta", 2], ["Gamma", 3]]],
      ["Project A", [["Alpha", 1]]],
    ]

    html = simple_form_for "", method: :get, url: "/" do |f|
      concat(f.input :category_id,
                     as: :grouped_select,
                     collection: grouped_collection,
                     filterable: true,
                     group_method: :last,
                     group_label_method: :first,
                     include_blank: "Select category")
    end

    page = Capybara.string(html)
    select = page.find("select[name='category_id']")

    assert_includes select["data-controller"].split, "f-input-collection-filterable"
    assert_includes select["class"].split, "f-input--collection-filterable"
    assert_nil select["data-f-input-collection-remote-select-url-value"]
    assert_equal "Select category", select["data-f-input-collection-filterable-include-blank-value"]

    assert page.has_css?("select[name='category_id'] > option[value='']", text: "Select category")
    assert page.has_css?("select[name='category_id'] optgroup[label='Project B'] option[value='2']", text: "Beta")
    assert page.has_css?("select[name='category_id'] optgroup[label='Project B'] option[value='3']", text: "Gamma")
    assert page.has_css?("select[name='category_id'] optgroup[label='Project A'] option[value='1']", text: "Alpha")
    assert_equal 3, page.all("select[name='category_id'] optgroup option").count
  end

  test "remote collection select keeps remote controller" do
    html = simple_form_for "", method: :get, url: "/" do |f|
      concat(f.input :record_id,
                     collection: [["Existing", "1"]],
                     filterable: true,
                     include_blank: "Select record",
                     remote: "/autocomplete")
    end

    page = Capybara.string(html)
    select = page.find("select[name='record_id']")

    assert_includes select["data-controller"].split, "f-input-collection-remote-select"
    assert_not_includes select["data-controller"].split, "f-input-collection-filterable"
    assert_equal "/autocomplete", select["data-f-input-collection-remote-select-url-value"]
    assert_nil select["data-f-input-collection-filterable-include-blank-value"]
  end
end
