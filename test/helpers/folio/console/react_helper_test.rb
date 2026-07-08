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
    assert_nil wrap["data-serialization"]
    assert_nil wrap["data-input-name"]
  end

  test "react_ordered_multiselect renders virtual remote array data" do
    author = create(:dummy_blog_author,
                    first_name: "Ada",
                    last_name: "Lovelace")

    wrap = ordered_multiselect_wrap(build(:dummy_blog_article),
                                    relation_name: :issue_ids,
                                    virtual: {
                                      class_name: "Dummy::Blog::Author",
                                      selected: [author],
                                      input_name: "dummy_blog_article[issue_ids][]",
                                    },
                                    label_method: :full_name)
    params = Rack::Utils.parse_nested_query(URI.parse(wrap["data-url"]).query)
    items = data_json(wrap, "items")

    assert_includes wrap["data-url"], "/console/api/autocomplete/react_select"
    assert_equal "Dummy::Blog::Author", params["class_names"]
    assert_equal "full_name", params["label_method"]
    assert_equal "array", wrap["data-serialization"]
    assert_equal "dummy_blog_article[issue_ids][]", wrap["data-input-name"]
    assert_nil wrap["data-param-base"]
    assert_nil wrap["data-foreign-key"]
    assert_equal [], data_json(wrap, "removed-items")
    assert_equal author.id, items[0]["value"]
    assert_equal "Ada Lovelace", items[0]["label"]
  end

  test "react_ordered_multiselect keeps explicit label in virtual mode" do
    issue = create(:dummy_blog_author,
                   first_name: "Project > Issue",
                   last_name: "1")

    form = ordered_multiselect_form(build(:dummy_blog_article),
                                    relation_name: :issue_ids,
                                    virtual: {
                                      class_name: "Dummy::Blog::Author",
                                      selected: [issue],
                                      input_name: "dummy_blog_article[issue_ids][]",
                                    },
                                    label_method: :full_name,
                                    label: "Vydání")
    wrap = form.find(".folio-react-wrap--ordered-multiselect")
    items = data_json(wrap, "items")
    label = form.find("label")

    assert_equal "Vydání", label.text
    assert_includes label["class"].split, "string"
    assert_includes label["class"].split, "optional"
    assert_includes label["class"].split, "form-label"
    assert_equal "Project > Issue 1", items[0]["label"]
  end

  test "react_ordered_multiselect keeps visible error feedback" do
    article = build(:dummy_blog_article)
    article.errors.add(:authors, "must be present")
    form = ordered_multiselect_form(article)
    feedback = form.find(".invalid-feedback")

    assert_includes form.find(".form-group")["class"].split, "form-group-invalid"
    assert_includes feedback["class"].split, "d-block"
    assert_equal "Autoři must be present", feedback.text
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

  test "react_ordered_multiselect renders virtual grouped local collection options" do
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
                                    relation_name: :issue_ids,
                                    virtual: {
                                      class_name: "Dummy::Blog::Author",
                                      selected: [first_author],
                                      input_name: "dummy_blog_article[issue_ids][]",
                                    },
                                    label_method: :full_name,
                                    collection:,
                                    group_method: :records,
                                    group_label_method: :label)
    options = data_json(wrap, "options")
    items = data_json(wrap, "items")

    assert_nil wrap["data-url"]
    assert_equal "array", wrap["data-serialization"]
    assert_equal "dummy_blog_article[issue_ids][]", wrap["data-input-name"]
    assert_equal "First group", options[0]["label"]
    assert_equal first_author.id, options[0]["options"][0]["id"]
    assert_equal "Ada Lovelace", options[0]["options"][0]["label"]
    assert_equal "Dummy::Blog::Author", options[0]["options"][0]["type"]
    assert_equal "Second group", options[1]["label"]
    assert_equal second_author.id, options[1]["options"][0]["id"]
    assert_equal first_author.id, items[0]["value"]
  end

  test "react_ordered_multiselect uses explicit selected through records for items" do
    article = create(:dummy_blog_article)
    first_author = create(:dummy_blog_author,
                          site: article.site,
                          locale: article.locale,
                          first_name: "Ada",
                          last_name: "Lovelace")
    second_author = create(:dummy_blog_author,
                           site: article.site,
                           locale: article.locale,
                           first_name: "Grace",
                           last_name: "Hopper")
    article.authors << first_author
    article.authors << second_author

    first_link = article.author_article_links.find_by!(author: first_author)

    wrap = ordered_multiselect_wrap(article,
                                    selected_through_records: [first_link])
    items = data_json(wrap, "items")

    assert_equal "#{article.model_name.param_key}[author_article_links_attributes]",
                 wrap["data-param-base"]
    assert_equal "dummy_blog_author_id", wrap["data-foreign-key"]
    assert_equal [first_author.id], items.map { |item| item["value"] }
    assert_equal ["Ada Lovelace"], items.map { |item| item["label"] }
  end

  test "react_ordered_multiselect keeps selected through records marked for destruction as removed items" do
    article = create(:dummy_blog_article)
    kept_author = create(:dummy_blog_author,
                         site: article.site,
                         locale: article.locale,
                         first_name: "Ada",
                         last_name: "Lovelace")
    removed_author = create(:dummy_blog_author,
                            site: article.site,
                            locale: article.locale,
                            first_name: "Grace",
                            last_name: "Hopper")
    article.authors << kept_author
    article.authors << removed_author

    kept_link = article.author_article_links.find_by!(author: kept_author)
    removed_link = article.author_article_links.find_by!(author: removed_author)
    removed_link.mark_for_destruction

    wrap = ordered_multiselect_wrap(article,
                                    selected_through_records: [kept_link, removed_link])
    items = data_json(wrap, "items")
    removed_items = data_json(wrap, "removed-items")

    assert_equal [kept_author.id], items.map { |item| item["value"] }
    assert_equal [removed_link.id], removed_items.map { |item| item["id"] }
    assert_equal [removed_author.id], removed_items.map { |item| item["value"] }
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
      ordered_multiselect_form(record, relation_name:, **options)
        .find(".folio-react-wrap--ordered-multiselect")
    end

    def ordered_multiselect_form(record, relation_name: :authors, **options)
      html = simple_form_for(record, url: "/") do |f|
        concat(react_ordered_multiselect(f, relation_name, **options))
      end

      Capybara.string(html)
    end

    def data_json(wrap, key)
      JSON.parse(wrap["data-#{key}"])
    end
end
