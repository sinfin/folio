# frozen_string_literal: true

require "test_helper"

class Folio::Console::TransportsControllerTest < Folio::Console::BaseControllerTest
  test "out" do
    sign_in @admin
    assert_nil Folio::Page.find_by(id: 1)
    assert_raises(ActiveRecord::RecordNotFound) do
      get out_console_transport_path(class_name: "Folio::Page", id: 1)
    end

    menu = create(:folio_menu)
    sign_in @admin
    assert_raises(ActionController::ParameterMissing) do
      get out_console_transport_path(class_name: "Folio::Menu", id: menu)
    end

    page = create(:folio_page)

    sign_in @admin
    get out_console_transport_path(class_name: "Folio::Page", id: page.id)
    assert_response :success
  end

  test "in" do
    sign_in @admin
    get in_console_transport_path
    assert_response :success

    sign_in @admin
    assert_raises(ActiveRecord::RecordNotFound) do
      get in_console_transport_path(class_name: "Folio::Page", id: 1)
    end

    page = create(:folio_page)

    sign_in @admin
    get in_console_transport_path(class_name: "Folio::Page", id: page.id)
    assert_response :success
  end

  test "transport new" do
    assert_nil(Folio::Page.last)

    hash = {
      id: 123,
      class_name: "Folio::Page",
      attributes: {
        slug: "my-custom-slug",
        published: false,
        published_at: "2020-12-27T09:06:00+01:00",
        title: "My custom title",
      }
    }

    sign_in @admin
    post transport_console_transport_path, params: {
      yaml_string: hash.to_yaml,
    }
    page = Folio::Page.last
    assert(Folio::Page.last)
    assert_redirected_to url_for([:edit, :console, page])

    assert_equal(hash[:attributes][:slug], page.slug)
    assert_equal(hash[:attributes][:title], page.title)
  end

  test "transport existing" do
    page = create(:folio_page, slug: "old-slug", title: "Old title")
    create_atom(Dummy::Atom::Text, :content, placement: page)
    id = page.id
    assert_equal(1, page.atoms.count)

    hash = {
      id: 123,
      class_name: "Folio::Page",
      attributes: {
        slug: "my-custom-slug",
        published: false,
        published_at: "2020-12-27T09:06:00+01:00",
        title: "My custom title",
      },
    }

    sign_in @admin
    post transport_console_transport_path(class_name: "Folio::Page", id: id), params: {
      yaml_string: hash.to_yaml,
    }

    page.reload

    assert_equal(0, page.atoms.count)
    assert_redirected_to url_for([:edit, :console, page])

    assert_equal(id, page.id)
    assert_equal(hash[:attributes][:slug], page.slug)
    assert_equal(hash[:attributes][:title], page.title)
  end
end
