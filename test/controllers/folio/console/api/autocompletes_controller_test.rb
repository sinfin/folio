# frozen_string_literal: true

require "test_helper"

class Folio::Console::Api::AutocompletesControllerTest < Folio::Console::BaseControllerTest
  test "show" do
    get console_api_autocomplete_path(klass: "Folio::Page", q: "foo")
    json = JSON.parse(response.body)
    assert_equal([], json["data"])

    create(:folio_page, title: "Foo bar baz")
    get console_api_autocomplete_path(klass: "Folio::Page", q: "foo")
    json = JSON.parse(response.body)
    assert_equal(["Foo bar baz"], json["data"])

    superadmin.forget_me!
    sign_out superadmin
    get console_api_autocomplete_path(klass: "Folio::Page", q: "a")
    json = JSON.parse(response.body)
    assert_equal(401, json["errors"][0]["status"])
  end

  test "field" do
    # field works only for fields selected in `Model.by_query` method
    # so eg. not for page.meta_title, but just page.title and page.perex
    get field_console_api_autocomplete_path(klass: "Folio::Page", q: "foo", field: "title")
    json = JSON.parse(response.body)
    assert_equal([], json["data"])

    _page1 = create(:folio_page, title: "Page 1", perex: "foo & baz")
    _page2 = create(:folio_page, title: "Foo bar", perex: "page 2")

    get field_console_api_autocomplete_path(klass: "Folio::Page", q: "foo", field: "title")
    json = JSON.parse(response.body)
    assert_equal(["Foo bar"], json["data"])

    get field_console_api_autocomplete_path(klass: "Folio::Page", q: "foo", field: "perex")
    json = JSON.parse(response.body)
    assert_equal(["foo & baz"], json["data"])

    superadmin.forget_me!
    sign_out superadmin
    get field_console_api_autocomplete_path(klass: "Folio::Page", q: "a", field: "title")
    json = JSON.parse(response.body)
    assert_equal(401, json["errors"][0]["status"])
  end

  test "selectize" do
    get selectize_console_api_autocomplete_path(klass: "Folio::Page", q: "foo")
    json = JSON.parse(response.body)
    assert_equal([], json["data"])

    create(:folio_page, title: "Foo bar baz")
    get selectize_console_api_autocomplete_path(klass: "Folio::Page", q: "foo")
    json = JSON.parse(response.body)
    assert_equal(1, json["data"].size)
    assert_equal("Foo bar baz", json["data"][0]["text"])

    superadmin.forget_me!
    sign_out superadmin
    get selectize_console_api_autocomplete_path(klass: "Folio::Page", q: "a")
    json = JSON.parse(response.body)
    assert_equal(401, json["errors"][0]["status"])
  end

  test "select2" do
    get select2_console_api_autocomplete_path(klass: "Folio::Page", q: "foo")
    json = JSON.parse(response.body)
    assert_equal([], json["results"])

    create(:folio_page, title: "Foo bar baz")
    get select2_console_api_autocomplete_path(klass: "Folio::Page", q: "foo")
    json = JSON.parse(response.body)
    assert_equal(1, json["results"].size)
    assert_equal("Foo bar baz", json["results"][0]["text"])

    superadmin.forget_me!
    sign_out superadmin
    get select2_console_api_autocomplete_path(klass: "Folio::Page", q: "a")
    json = JSON.parse(response.body)
    assert_equal(401, json["errors"][0]["status"])
  end

  test "react_select" do
    get react_select_console_api_autocomplete_path(class_names: "Folio::Page", q: "foo")
    json = JSON.parse(response.body)
    assert_equal([], json["data"])

    create(:folio_page, title: "Foo bar baz")
    get react_select_console_api_autocomplete_path(class_names: "Folio::Page", q: "foo")
    json = JSON.parse(response.body)
    assert_equal(1, json["data"].size)
    assert_equal("Foo bar baz", json["data"][0]["text"])
    assert_equal("Folio::Page", json["data"][0]["type"])

    superadmin.forget_me!
    sign_out superadmin
    get react_select_console_api_autocomplete_path(class_names: "Folio::Page", q: "a")
    json = JSON.parse(response.body)
    assert_equal(401, json["errors"][0]["status"])
  end

  test "it respects accessible_by scope" do
    same_part = "emailme"
    superadmin = create(:folio_user, superadmin: true, email: "#{same_part}@supedamin.com", first_name: "Superadmin")
    administrator = create(:folio_user, email: "#{same_part}@administrator.com", first_name: "Administrator")
    administrator.set_roles_for(site: Folio.main_site, roles: ["administrator"])
    administrator.save!
    manager = create(:folio_user, email: "#{same_part}@manager.com", first_name: "Manager")
    manager.set_roles_for(site: Folio.main_site, roles: ["manager"])
    manager.save!

    sign_in superadmin

    get field_console_api_autocomplete_path(klass: "Folio::User", q: same_part, field: "email")

    assert_equal([administrator, manager, superadmin].collect(&:email),
                 JSON.parse(response.body)["data"])

    sign_out superadmin
    sign_in administrator

    get field_console_api_autocomplete_path(klass: "Folio::User", q: same_part, field: "email")

    assert_equal([administrator, manager].collect(&:email),
                 JSON.parse(response.body)["data"])

    sign_out administrator
    sign_in manager

    get field_console_api_autocomplete_path(klass: "Folio::User", q: same_part, field: "email")

    assert_equal([manager.email],
                 JSON.parse(response.body)["data"])

    # check other autocomplete methods to obey accessible_by scope

    get console_api_autocomplete_path(klass: "Folio::User", q: same_part)

    assert_equal([manager.to_autocomplete_label],
                 JSON.parse(response.body)["data"])

    get selectize_console_api_autocomplete_path(klass: "Folio::User", q: same_part)

    assert_equal(["#{manager.to_autocomplete_label} <#{manager.email}>"],
                 JSON.parse(response.body)["data"].collect { |r| r["text"] })

    get select2_console_api_autocomplete_path(klass: "Folio::User", q: same_part)

    assert_equal(["#{manager.to_autocomplete_label} <#{manager.email}>"],
                 JSON.parse(response.body)["results"].collect { |r| r["text"] })

    get react_select_console_api_autocomplete_path(class_names: "Folio::User", q: same_part)

    assert_equal(["#{manager.to_autocomplete_label} <#{manager.email}>"],
                 JSON.parse(response.body)["data"].collect { |r| r["text"] })
  end
end
