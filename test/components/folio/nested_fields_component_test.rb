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
    assert_no_selector('.f-nested-fields__control--destroy[data-controller*="f-tooltip"]')
    assert_selector(".f-nested-fields__control--destroy + .f-nested-fields__control--duplicate")
    assert_selector('.f-nested-fields__control--arrow[data-action*="onPositionUpClick"]')
    assert_no_selector('.f-nested-fields__control--arrow[data-controller*="f-tooltip"]')
    assert_selector('.f-nested-fields__control--sortable-handle[data-f-nested-fields-target="sortableHandle"]')
    assert_no_selector('.f-nested-fields__control--sortable-handle[data-controller*="f-tooltip"]')
    assert_selector('.f-nested-fields__control--arrow[data-action*="onPositionDownClick"]')
    assert_selector('.f-nested-fields__control--duplicate[data-action*="onDuplicateClick"]')
    assert_no_selector('.f-nested-fields__control--duplicate[data-controller*="f-tooltip"]')
  end

  test "does not render duplicate control by default" do
    render_virtual_component(duplicate: false)

    assert_no_selector(".f-nested-fields__control--duplicate")
  end

  test "renders opt-in add more control for each virtual field and template" do
    render_virtual_component(add_more: true)

    assert_selector('.f-nested-fields__fields[data-nested-fields-row-key="item_0"] .f-nested-fields__control--add-more[data-action*="onAddMoreClick"]')
    assert_no_selector('.f-nested-fields__control--add-more[data-controller*="f-tooltip"]')
    assert_match(%r{<template[^>]*class="f-nested-fields__template"[\s\S]*f-nested-fields__control--add-more},
                 rendered_content)
  end

  test "renders selected-value hiding opt-in" do
    render_virtual_component(hide_selected_value_for: :title)

    assert_selector('[data-f-nested-fields-hide-selected-value-for-value="title"]')
    assert_selector('[data-action*="change->f-nested-fields#onHideSelectedValueSelectChange"]')
  end

  test "renders control tooltips when enabled" do
    render_virtual_component(add_more: true,
                             control_tooltips: true,
                             duplicate: true)

    assert_selector('.f-nested-fields__control--destroy[data-controller*="f-tooltip"]')
    assert_selector('.f-nested-fields__control--add-more[data-controller*="f-tooltip"]')
    assert_selector('.f-nested-fields__control--duplicate[data-controller*="f-tooltip"]')
    assert_selector('.f-nested-fields__control--arrow[data-action*="onPositionUpClick"][data-controller*="f-tooltip"]')
    assert_selector('.f-nested-fields__control--arrow[data-action*="onPositionDownClick"][data-controller*="f-tooltip"]')
    assert_no_selector('.f-nested-fields__control--sortable-handle[data-controller*="f-tooltip"]')
  end

  test "renders add more control above duplicate control" do
    render_virtual_component(add_more: true,
                             duplicate: true)

    assert_selector(".f-nested-fields__control--destroy + .f-nested-fields__control--add-more + .f-nested-fields__control--duplicate")
  end

  test "renders add more template without regular add button" do
    render_virtual_component(add: false,
                             add_more: true)

    assert_no_selector(".f-nested-fields__add")
    assert_selector('.f-nested-fields__fields[data-nested-fields-row-key="item_0"] .f-nested-fields__control--add-more[data-action*="onAddMoreClick"]')
    assert_selector(".f-nested-fields__template", visible: :all)
  end

  private
    def render_virtual_component(duplicate: false,
                                 add: true,
                                 add_more: false,
                                 control_tooltips: nil,
                                 hide_selected_value_for: nil)
      record = VirtualRecord.new(cards: [VirtualCard.new(title: "First")])
      view = vc_test_controller.view_context

      view.simple_form_for(record, url: "/", as: "record") do |f|
        render_inline(Folio::NestedFieldsComponent.new(
          f:,
          key: :cards,
          add:,
          add_more:,
          virtual: {
            new_object: VirtualCard.new,
            fields_key: :data,
          },
          duplicate:,
          control_tooltips:,
          hide_selected_value_for:,
        )) do |nested_fields|
          nested_fields.g.input(:title, label: false)
        end
      end
    end
end
