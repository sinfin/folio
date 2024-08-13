# frozen_string_literal: true

require "test_helper"

class Folio::Console::AttributeTypesControllerTest < Folio::Console::BaseControllerTest
  test "index" do
    get url_for([:console, Folio::AttributeType])

    assert_response :success

    create(:dummy_folio_attribute_type)

    get url_for([:console, Folio::AttributeType])

    assert_response :success
  end

  test "new" do
    get url_for([:console, Folio::AttributeType, action: :new])

    assert_response :success
  end

  test "edit" do
    model = create(:dummy_folio_attribute_type)

    get url_for([:edit, :console, model])

    assert_response :success
  end

  test "create" do
    params = build(:dummy_folio_attribute_type).serializable_hash.merge(type: "Dummy::AttributeType::Page")

    assert_difference("Folio::AttributeType.count", 1) do
      post url_for([:console, Folio::AttributeType]), params: {
        attribute_type: params,
      }
    end
  end

  test "update" do
    model = create(:dummy_folio_attribute_type)
    assert_not_equal("Title", model.title)

    put url_for([:console, model]), params: {
      attribute_type: {
        title: "Title",
      },
    }

    assert_redirected_to url_for([:edit, :console, model])
    assert_equal("Title", model.reload.title)
  end

  test "destroy" do
    model = create(:dummy_folio_attribute_type)

    delete url_for([:console, model])

    assert_redirected_to url_for([:console, Folio::AttributeType])
    assert_not(Folio::AttributeType.exists?(id: model.id))
  end
end
