# frozen_string_literal: true

require "test_helper"

class Folio::Console::AtomsControllerTest < Folio::Console::BaseControllerTest
  test "index" do
    get console_atoms_path
    assert_response(:ok)
  end

  test "preview" do
    post preview_console_atoms_path, params: JSON.parse('{"atoms_attributes":[{"id":1,"type":"Folio::Atom::Text","position":1,"placement_type":"Folio::Page","placement_id":1,"data":null,"content":"lorem ipsum"},{"id":2,"type":"Folio::Atom::Text","position":2,"placement_type":"Folio::Page","placement_id":1,"data":null,"content":"lorem ipsum"},{"id":3,"type":"Folio::Atom::Text","position":3,"placement_type":"Folio::Page","placement_id":1,"data":null,"_destroy":true,"content":"lorem ipsum"}]}')
    assert_response(:ok)
  end

  test "validate" do
    post validate_console_atoms_path, params: {
      atoms: [
        {
          type: "Dummy::Atom::Gallery",
          placement_type: "Folio::Page",
          placement_id: create(:folio_page).id,
        }
      ]
    }
    assert_response(:ok)
    json = JSON.parse(response.body)
    assert_equal(false, json.first["valid"])
    assert_not_nil(json.first["errors"])
    assert_not_nil(json.first["messages"])
    assert_equal(["image_placements"], json.first["errors"].keys)
  end
end
