# frozen_string_literal: true

require "test_helper"

class Folio::Console::Tiptap::Overlay::Form::LayoutComponentTest < Folio::Console::ComponentTest
  class CustomFieldsComponent < Folio::Console::ApplicationComponent
    def initialize(f:)
      @f = f
    end

    def call
      content_tag(:div, class: "custom-fields-component") do
        safe_join([
          @f.hidden_field(:internal_uid),
          @f.input(:title),
        ])
      end
    end
  end

  class DefaultAsideNode < Folio::Tiptap::Node
    tiptap_node structure: {
      url: :string,
      cover: :image,
      title: :string,
    }
  end

  class FlatNode < Folio::Tiptap::Node
    tiptap_node structure: {
      cover: :image,
      title: :string,
    }, form_layout: nil
  end

  class CustomLayoutNode < Folio::Tiptap::Node
    tiptap_node structure: {
      url: :string,
      cover: :image,
      title: :string,
    }, form_layout: {
      rows: [
        :url,
        {
          columns: [
            :cover,
            { rows: [:title] },
          ],
        },
      ],
    }
  end

  class CustomFieldsNode < Folio::Tiptap::Node
    tiptap_node structure: {
      internal_uid: { type: :string, hidden: true },
      title: :string,
    }, form_fields_component: ->(f:) { CustomFieldsComponent.new(f:) }
  end

  class NilCustomFieldsNode < Folio::Tiptap::Node
    tiptap_node structure: {
      title: :string,
    }, form_fields_component: ->(f:) { nil }
  end

  class NestedCustomFieldsNode < Folio::Tiptap::Node
    tiptap_node nested: true,
                structure: {
                  internal_uid: { type: :string, hidden: true },
                  title: :string,
                },
                form_fields_component: ->(f:) { CustomFieldsComponent.new(f:) }
  end

  test "renders default aside attachment layout" do
    render_layout_component(DefaultAsideNode.new)

    assert_selector(".f-c-tiptap-overlay-form-layout")
    assert_selector(".f-c-tiptap-overlay-form-layout__row > .f-c-tiptap-overlay-form-layout__col:first-child [name='tiptap_node_attrs[data][cover_placement_attributes][file_id]']",
                    visible: :all)
    assert_selector(".f-c-tiptap-overlay-form-layout__row > .f-c-tiptap-overlay-form-layout__col [name='tiptap_node_attrs[data][title]']")
  end

  test "renders only base column classes" do
    render_layout_component(DefaultAsideNode.new)

    assert_selector(".f-c-tiptap-overlay-form-layout__col", count: 3)
    class_names = Nokogiri::HTML(rendered_content)
                         .css(".f-c-tiptap-overlay-form-layout__col")
                         .map { |element| element[:class] }

    assert_equal ["f-c-tiptap-overlay-form-layout__col"] * 3,
                 class_names
  end

  test "renders flat layout for explicit nil form_layout" do
    render_layout_component(FlatNode.new)

    assert_selector(".f-c-tiptap-overlay-form-layout")
    assert_selector("[name='tiptap_node_attrs[data][cover_placement_attributes][file_id]']",
                    visible: :all)
    assert_selector("[name='tiptap_node_attrs[data][title]']")
  end

  test "renders custom rows and columns layout" do
    render_layout_component(CustomLayoutNode.new)

    assert_selector(".f-c-tiptap-overlay-form-layout__row", count: 3)
    assert_selector("[name='tiptap_node_attrs[data][url]']")
    assert_selector("[name='tiptap_node_attrs[data][cover_placement_attributes][file_id]']",
                    visible: :all)
    assert_selector("[name='tiptap_node_attrs[data][title]']")
  end

  test "renders custom fields instead of the built-in layout" do
    render_layout_component(CustomFieldsNode.new(internal_uid: "stable-uid", title: "Custom title"))

    assert_selector(".custom-fields-component")
    assert_selector('[name="tiptap_node_attrs[data][internal_uid]"][value="stable-uid"]', visible: :all)
    assert_selector('[name="tiptap_node_attrs[data][title]"][value="Custom title"]')
    assert_no_selector(".f-c-tiptap-overlay-form-layout__row")
  end

  test "allows a custom fields component factory to omit the fields body" do
    render_layout_component(NilCustomFieldsNode.new(title: "Hidden title"))

    assert_no_selector('[name="tiptap_node_attrs[data][title]"]')
  end

  test "renders custom fields for nested nodes" do
    render_layout_component(NestedCustomFieldsNode.new(internal_uid: "nested-uid", title: "Nested title"))

    assert_selector(".custom-fields-component")
    assert_selector('[name="tiptap_node_attrs[data][internal_uid]"][value="nested-uid"]', visible: :all)
    assert_selector('[name="tiptap_node_attrs[data][title]"][value="Nested title"]')
  end

  private
    def render_layout_component(node)
      with_controller_class(Folio::Console::PagesController) do
        with_request_url "/console/pages/new" do
          view = vc_test_controller.view_context

          view.simple_form_for(node, url: "/", as: "tiptap_node_attrs[data]") do |f|
            render_inline(Folio::Console::Tiptap::Overlay::Form::LayoutComponent.new(
              f:,
              node:,
            ))
          end
        end
      end
    end
end
