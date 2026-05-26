# frozen_string_literal: true

require "test_helper"

class Folio::NestedFieldsComponentTest < Folio::ComponentTest
  class VirtualRecord
    include ActiveModel::Model

    attr_accessor :cards
  end

  class VirtualCard
    include ActiveModel::Model

    attr_accessor :title
  end

  test "renders virtual collection fields with stable row keys" do
    render_virtual_component

    assert_selector(".f-nested-fields")
    assert_selector('[data-controller="f-nested-fields"]')
    assert_selector('[data-f-nested-fields-virtual-value="true"]')
    assert_selector('[name="record[cards][item_0][data][title]"][value="First"]')
    assert_includes(rendered_content, 'name="record[cards][f-nested-fields-template-cards][data][title]"')
    assert_no_selector(".f-nested-fields__id-input", visible: :all)
    assert_no_selector(".f-nested-fields__destroy-input", visible: :all)
  end

  test "renders virtual reorder controls and opt-in duplicate control" do
    render_virtual_component(duplicate: true)

    assert_selector('.f-nested-fields__control--destroy[data-action*="onDestroyClick"]')
    assert_selector(".f-nested-fields__control--destroy + .f-nested-fields__control--duplicate")
    assert_selector('.f-nested-fields__control--arrow[data-action*="onPositionUpClick"]')
    assert_selector('.f-nested-fields__control--sortable-handle[data-f-nested-fields-target="sortableHandle"]')
    assert_selector('.f-nested-fields__control--arrow[data-action*="onPositionDownClick"]')
    assert_selector('.f-nested-fields__control--duplicate[data-action*="onDuplicateClick"]')
  end

  test "does not render duplicate control by default" do
    render_virtual_component(duplicate: false)

    assert_no_selector(".f-nested-fields__control--duplicate")
  end

  private
    def render_virtual_component(duplicate: false)
      record = VirtualRecord.new(cards: [
        VirtualCard.new(title: "First"),
      ])
      view = vc_test_controller.view_context

      view.simple_form_for(record, url: "/", as: "record") do |f|
        render_inline(Folio::NestedFieldsComponent.new(
          f:,
          key: :cards,
          virtual: {
            new_object: VirtualCard.new,
            fields_key: :data,
          },
          duplicate:,
        )) do |nested_fields|
          nested_fields.g.input(:title, label: false)
        end
      end
    end
end
