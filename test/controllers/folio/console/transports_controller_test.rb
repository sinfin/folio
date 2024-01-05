# frozen_string_literal: true

require "test_helper"

class Folio::Console::TransportsControllerTest < Folio::Console::BaseControllerTest
  test "out" do
    assert_nil Folio::Page.find_by(id: 1)

    assert_raises(ActiveRecord::RecordNotFound) do
      get out_console_transport_path(class_name: "Folio::Page", id: 1)
    end

    menu = create(:folio_menu_page)
    sign_in superadmin # needs to be done each time (?)

    ex = assert_raises(ActionController::ParameterMissing) do
      get out_console_transport_path(class_name: "Folio::Menu", id: menu.id)
    end

    assert_equal "param is missing or the value is empty: Non-transportable record", ex.message

    page = create(:folio_page)
    sign_in superadmin

    get out_console_transport_path(class_name: "Folio::Page", id: page.id)

    assert_response :success
  end

  test "in" do
    get in_console_transport_path
    assert_response :success

    assert_raises(ActiveRecord::RecordNotFound) do
      get in_console_transport_path(class_name: "Folio::Page", id: 1)
    end

    page = create(:folio_page)

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

    assert_difference("Folio::Page.count", 1) do
      post transport_console_transport_path, params: {
                                               yaml_string: hash.to_yaml(line_width: -1),
                                             }
    end

    page = Folio::Page.last
    assert page
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

    post transport_console_transport_path(class_name: "Folio::Page", id:), params: {
      yaml_string: hash.to_yaml(line_width: -1),
    }

    page.reload

    assert_equal(0, page.atoms.count)
    assert_redirected_to url_for([:edit, :console, page])

    assert_equal(id, page.id)
    assert_equal(hash[:attributes][:slug], page.slug)
    assert_equal(hash[:attributes][:title], page.title)
  end
end
