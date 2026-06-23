# frozen_string_literal: true

require "test_helper"

class Folio::Console::ReactHelperTest < ActionView::TestCase
  include Folio::Console::ReactHelper
  include SimpleForm::ActionViewExtensions::FormHelper

  Group = Struct.new(:label, :records)

  test "react_ordered_multiselect keeps remote autocomplete by default" do
    wrap = ordered_multiselect_wrap(build(:dummy_blog_article))

    assert_includes wrap["data-url"], "/console/api/autocomplete/react_select"
    assert_nil wrap["data-options"]
  end

  test "react_ordered_multiselect renders local collection options" do
    author = create(:dummy_blog_author,
                    first_name: "Ada",
                    last_name: "Lovelace")
    wrap = ordered_multiselect_wrap(build(:dummy_blog_article),
                                    collection: [author])
    options = data_json(wrap, "options")

    assert_nil wrap["data-url"]
    assert_equal author.id, options[0]["id"]
    assert_equal author.id, options[0]["value"]
    assert_equal "Ada Lovelace", options[0]["label"]
    assert_equal "Dummy::Blog::Author", options[0]["type"]
  end

  test "react_ordered_multiselect renders local array pair options" do
    wrap = ordered_multiselect_wrap(build(:dummy_blog_article),
                                    collection: [["Ada Lovelace", 1]])
    options = data_json(wrap, "options")

    assert_nil wrap["data-url"]
    assert_equal 1, options[0]["id"]
    assert_equal 1, options[0]["value"]
    assert_equal "Ada Lovelace", options[0]["label"]
    assert_equal "Dummy::Blog::Author", options[0]["type"]
  end

  test "react_ordered_multiselect renders grouped local collection options" do
    first_author = create(:dummy_blog_author,
                          first_name: "Ada",
                          last_name: "Lovelace")
    second_author = create(:dummy_blog_author,
                           first_name: "Grace",
                           last_name: "Hopper")
    collection = [
      Group.new("First group", [first_author]),
      Group.new("Second group", [second_author]),
    ]

    wrap = ordered_multiselect_wrap(build(:dummy_blog_article),
                                    collection:,
                                    group_method: :records,
                                    group_label_method: :label)
    options = data_json(wrap, "options")

    assert_nil wrap["data-url"]
    assert_equal "First group", options[0]["label"]
    assert_equal first_author.id, options[0]["options"][0]["id"]
    assert_equal "Second group", options[1]["label"]
    assert_equal second_author.id, options[1]["options"][0]["id"]
  end

  test "react_ordered_multiselect keeps selected items with local options" do
    article = create(:dummy_blog_article)
    author = create(:dummy_blog_author,
                    site: article.site,
                    locale: article.locale)
    article.authors << author

    wrap = ordered_multiselect_wrap(article,
                                    collection: [author],
                                    atom_setting: :authors)
    items = data_json(wrap, "items")

    assert_equal "authors", wrap["data-atom-setting"]
    assert_equal author.id, items[0]["value"]
    assert_equal author.to_console_label, items[0]["label"]
  end

  private
    def ordered_multiselect_wrap(record, relation_name: :authors, **options)
      html = simple_form_for(record, url: "/") do |f|
        concat(react_ordered_multiselect(f, relation_name, **options))
      end

      Capybara.string(html).find(".folio-react-wrap--ordered-multiselect")
    end

    def data_json(wrap, key)
      JSON.parse(wrap["data-#{key}"])
    end
end
