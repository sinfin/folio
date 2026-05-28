# frozen_string_literal: true

require "test_helper"

class Folio::Console::Tiptap::Overlay::FormComponentTest < Folio::Console::ComponentTest
  class NestedCard < Folio::Tiptap::Node
    tiptap_node nested: true,
                structure: {
                   title: :string,
                   content: :text,
                 }

    validates :title,
              presence: true
  end

  class CardGroup < Folio::Tiptap::Node
    tiptap_node structure: {
      cards: {
        type: :nested_nodes,
        node_class: NestedCard,
      },
    }
  end

  class CarouselItem < Folio::Tiptap::Node
    tiptap_node nested: true,
                structure: {
                  url: { type: :url_json, disable_label: true },
                  cover: :image,
                  badge_label: :string,
                  title: :string,
                }
  end

  class Carousel < Folio::Tiptap::Node
    tiptap_node structure: {
      items: {
        type: :nested_nodes,
        node_class: CarouselItem,
      },
    }
  end

  class FlatCarouselItem < Folio::Tiptap::Node
    tiptap_node nested: true,
                structure: {
                  cover: :image,
                  title: :string,
                },
                form_layout: nil
  end

  class FlatCarousel < Folio::Tiptap::Node
    tiptap_node structure: {
      items: {
        type: :nested_nodes,
        node_class: FlatCarouselItem,
      },
    }
  end

  def test_render
    with_controller_class(Folio::Console::PagesController) do
      with_request_url "/console/pages/new" do
        node = Dummy::Tiptap::Node::Card.new
        render_inline(Folio::Console::Tiptap::Overlay::FormComponent.new(node:))

        assert_selector(".f-c-tiptap-overlay-form")
      end
    end
  end

  test "renders nested node inputs with stable keyed param names" do
    with_controller_class(Folio::Console::PagesController) do
      with_request_url "/console/pages/new" do
        node = CardGroup.new(cards: [
          nested_attrs(title: "First card", content: "Body"),
        ])

        render_inline(Folio::Console::Tiptap::Overlay::FormComponent.new(node:))

        assert_selector("fieldset .f-nested-fields")
        assert_selector('[name="tiptap_node_attrs[data][cards][item_0][type]"][value="Folio::Console::Tiptap::Overlay::FormComponentTest::NestedCard"]',
                        visible: :all)
        assert_selector('[name="tiptap_node_attrs[data][cards][item_0][version]"][value="1"]',
                        visible: :all)
        assert_selector('[name="tiptap_node_attrs[data][cards][item_0][data][title]"][value="First card"]')
        assert_selector('textarea[name="tiptap_node_attrs[data][cards][item_0][data][content]"]',
                        text: "Body")
        assert_selector('.f-nested-fields__control--duplicate[data-action*="onDuplicateClick"]')
        assert_selector(".f-nested-fields__template", visible: :all)
        assert_includes(rendered_content, 'name="tiptap_node_attrs[data][cards][f-nested-fields-template-cards][data][title]"')
      end
    end
  end

  test "renders prebuilt nested node inputs for blank collection" do
    with_controller_class(Folio::Console::PagesController) do
      with_request_url "/console/pages/new" do
        render_inline(Folio::Console::Tiptap::Overlay::FormComponent.new(node: CardGroup.new))

        assert_selector("fieldset .f-nested-fields")
        assert_selector('[name="tiptap_node_attrs[data][cards][item_0][type]"][value="Folio::Console::Tiptap::Overlay::FormComponentTest::NestedCard"]',
                        visible: :all)
        assert_selector('[name="tiptap_node_attrs[data][cards][item_0][data][title]"]')
      end
    end
  end

  test "renders nested node field errors" do
    with_controller_class(Folio::Console::PagesController) do
      with_request_url "/console/pages/new" do
        node = CardGroup.new(cards: [
          nested_attrs(title: ""),
        ])
        node.valid?

        render_inline(Folio::Console::Tiptap::Overlay::FormComponent.new(node:))

        assert_selector('[name="tiptap_node_attrs[data][cards][item_0][data][title]"].is-invalid')
      end
    end
  end

  test "renders default aside attachment layout for nested node rows" do
    with_controller_class(Folio::Console::PagesController) do
      with_request_url "/console/pages/new" do
        render_inline(Folio::Console::Tiptap::Overlay::FormComponent.new(node: Carousel.new))

        assert_selector(".f-c-tiptap-overlay-form-nested-nodes__item-fields .f-c-tiptap-overlay-form-layout__row:nth-of-type(2) > .f-c-tiptap-overlay-form-layout__col:first-child [name='tiptap_node_attrs[data][items][item_0][data][cover_placement_attributes][file_id]']",
                        visible: :all)
        assert_selector(".f-c-tiptap-overlay-form-nested-nodes__item-fields .f-c-tiptap-overlay-form-layout__row:nth-of-type(2) > .f-c-tiptap-overlay-form-layout__col:nth-child(2) [name='tiptap_node_attrs[data][items][item_0][data][badge_label]']")
        assert_selector(".f-c-tiptap-overlay-form-nested-nodes__item-fields .f-c-tiptap-overlay-form-layout__row:nth-of-type(2) > .f-c-tiptap-overlay-form-layout__col:nth-child(2) [name='tiptap_node_attrs[data][items][item_0][data][title]']")
      end
    end
  end

  test "renders flat nested node rows with explicit nil form_layout" do
    with_controller_class(Folio::Console::PagesController) do
      with_request_url "/console/pages/new" do
        render_inline(Folio::Console::Tiptap::Overlay::FormComponent.new(node: FlatCarousel.new))

        assert_selector("[name='tiptap_node_attrs[data][items][item_0][data][cover_placement_attributes][file_id]']",
                        visible: :all)
        assert_selector("[name='tiptap_node_attrs[data][items][item_0][data][title]']")
      end
    end
  end

  private
    def nested_attrs(**data)
      {
        "type" => "Folio::Console::Tiptap::Overlay::FormComponentTest::NestedCard",
        "version" => 1,
        "data" => data,
      }
    end
end
