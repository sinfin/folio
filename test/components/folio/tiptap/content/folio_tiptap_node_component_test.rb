# frozen_string_literal: true

require "test_helper"

class Folio::Tiptap::Content::FolioTiptapNodeComponentTest < Folio::Tiptap::NodeComponentTest
  def test_render_basic_folio_tiptap_node
    prose_mirror_node = {
      "type" => "folioTiptapNode",
      "attrs" => {
        "type" => "Dummy::Tiptap::Node::Card",
        "data" => { "title" => "Test Card", "text" => "Test content" }
      }
    }

    render_inline(Folio::Tiptap::Content::FolioTiptapNodeComponent.new(record: build_mock_record, prose_mirror_node:, tiptap_content_information:))

    assert_selector(".d-tiptap-node-card")
  end

  def test_render_with_string_type_attribute
    prose_mirror_node = {
      "type" => "folioTiptapNode",
      "attrs" => {
        "type" => "Dummy::Tiptap::Node::Card",
        "data" => {
          "title" => "Image Card",
          "text" => "A card with image content"
        }
      }
    }

    render_inline(Folio::Tiptap::Content::FolioTiptapNodeComponent.new(record: build_mock_record, prose_mirror_node:, tiptap_content_information:))

    assert_selector(".d-tiptap-node-card")
  end

  def test_render_with_complex_data_attributes
    prose_mirror_node = {
      "type" => "folioTiptapNode",
      "attrs" => {
        "type" => "Dummy::Tiptap::Node::Card",
        "data" => {
          "title" => "Gallery Card",
          "text" => "A complex card with multiple attributes",
          "button_url_json" => {
            "href" => "https://example.com",
            "label" => "View Gallery"
          }
        }
      }
    }

    render_inline(Folio::Tiptap::Content::FolioTiptapNodeComponent.new(record: build_mock_record, prose_mirror_node:, tiptap_content_information:))

    assert_selector(".d-tiptap-node-card")
    assert_text("Gallery Card")
  end

  def test_render_with_nested_data_structure
    prose_mirror_node = {
      "type" => "folioTiptapNode",
      "attrs" => {
        "type" => "Dummy::Tiptap::Node::Card",
        "data" => {
          "title" => "Testimonial Card",
          "text" => "This is a great product!",
          "button_url_json" => {
            "href" => "/testimonials",
            "label" => "Read More",
            "target" => "_blank"
          }
        }
      }
    }

    render_inline(Folio::Tiptap::Content::FolioTiptapNodeComponent.new(record: build_mock_record, prose_mirror_node:, tiptap_content_information:))

    assert_selector(".d-tiptap-node-card")
    assert_text("Testimonial Card")
  end

  def test_render_with_empty_data
    prose_mirror_node = {
      "type" => "folioTiptapNode",
      "attrs" => {
        "type" => "Dummy::Tiptap::Node::Card",
        "data" => {}
      }
    }

    render_inline(Folio::Tiptap::Content::FolioTiptapNodeComponent.new(record: build_mock_record, prose_mirror_node:, tiptap_content_information:))

    assert_selector(".d-tiptap-node-card")
  end

  def test_render_with_no_data_attribute
    prose_mirror_node = {
      "type" => "folioTiptapNode",
      "attrs" => {
        "type" => "Dummy::Tiptap::Node::Card"
      }
    }

    render_inline(Folio::Tiptap::Content::FolioTiptapNodeComponent.new(record: build_mock_record, prose_mirror_node:, tiptap_content_information:))

    assert_selector(".d-tiptap-node-card")
  end

  def test_render_with_null_attributes
    prose_mirror_node = {
      "type" => "folioTiptapNode",
      "attrs" => {
        "type" => "Dummy::Tiptap::Node::Card",
        "data" => {
          "title" => "Test Title",
          "text" => nil,
          "button_url_json" => nil
        }
      }
    }

    render_inline(Folio::Tiptap::Content::FolioTiptapNodeComponent.new(record: build_mock_record, prose_mirror_node:, tiptap_content_information:))

    assert_selector(".d-tiptap-node-card")
    assert_text("Test Title")
  end

  def test_render_with_special_characters_in_data
    prose_mirror_node = {
      "type" => "folioTiptapNode",
      "attrs" => {
        "type" => "Dummy::Tiptap::Node::Card",
        "data" => {
          "title" => "Special chars: <>&\"'",
          "text" => "HTML content with <strong>formatting</strong>",
          "button_url_json" => {
            "href" => "https://example.com/special?param=value&other=true",
            "label" => "Visit & Learn"
          }
        }
      }
    }

    render_inline(Folio::Tiptap::Content::FolioTiptapNodeComponent.new(record: build_mock_record, prose_mirror_node:, tiptap_content_information:))

    assert_selector(".d-tiptap-node-card")
    # The component displays attributes as JSON, so special chars will be escaped
    assert_text("Special chars:")
  end



  def test_render_with_url_attributes
    prose_mirror_node = {
      "type" => "folioTiptapNode",
      "attrs" => {
        "type" => "Dummy::Tiptap::Node::Card",
        "data" => {
          "title" => "Embed Card",
          "text" => "Card with external content",
          "button_url_json" => {
            "href" => "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
            "label" => "Watch Video",
            "target" => "_blank",
            "rel" => "noopener"
          }
        }
      }
    }

    render_inline(Folio::Tiptap::Content::FolioTiptapNodeComponent.new(record: build_mock_record, prose_mirror_node:, tiptap_content_information:))

    assert_selector(".d-tiptap-node-card")
    assert_text("Embed Card")
  end

  def test_render_with_mixed_data_types
    prose_mirror_node = {
      "type" => "folioTiptapNode",
      "attrs" => {
        "type" => "Dummy::Tiptap::Node::Card",
        "data" => {
          "title" => "Mixed Data Card",
          "text" => "Card with various data types",
          "button_url_json" => {
            "href" => "/path/to/resource",
            "label" => "Learn More",
            "title" => "Click to learn more about this topic"
          }
        }
      }
    }

    render_inline(Folio::Tiptap::Content::FolioTiptapNodeComponent.new(record: build_mock_record, prose_mirror_node:, tiptap_content_information:))

    assert_selector(".d-tiptap-node-card")
    assert_text("Mixed Data Card")
  end

  def test_render_with_json_data_display
    prose_mirror_node = {
      "type" => "folioTiptapNode",
      "attrs" => {
        "type" => "Dummy::Tiptap::Node::Card",
        "data" => {
          "title" => "JSON Display Test",
          "text" => "Testing JSON serialization"
        }
      }
    }

    render_inline(Folio::Tiptap::Content::FolioTiptapNodeComponent.new(record: build_mock_record, prose_mirror_node:, tiptap_content_information:))

    assert_selector(".d-tiptap-node-card")
    # The CardComponent displays attributes as JSON
    assert_text("JSON Display Test")
    assert_text("Testing JSON serialization")
  end

  def test_render_validates_node_attributes
    prose_mirror_node = {
      "type" => "folioTiptapNode",
      "attrs" => {
        "type" => "Dummy::Tiptap::Node::Card",
        "data" => {
          "title" => "", # Empty title should fail validation
          "text" => "Valid content"
        }
      }
    }


    # The component should still render even with validation errors
    render_inline(Folio::Tiptap::Content::FolioTiptapNodeComponent.new(record: build_mock_record, prose_mirror_node:, tiptap_content_information:))
    assert_selector(".d-tiptap-node-card")
  end

  def test_component_renders_ui_card_component
    prose_mirror_node = {
      "type" => "folioTiptapNode",
      "attrs" => {
        "type" => "Dummy::Tiptap::Node::Card",
        "data" => {
          "title" => "UI Component Test",
          "text" => "Testing the UI card component rendering"
        }
      }
    }

    render_inline(Folio::Tiptap::Content::FolioTiptapNodeComponent.new(record: build_mock_record, prose_mirror_node:, tiptap_content_information:))

    assert_selector(".d-tiptap-node-card")
    assert_text("Dummy Card Component from API")
  end

  def test_component_handles_invalid_folio_tiptap_node_type
    # this should fail as we catch it in Folio::Tiptap::Content::ProseMirrorNodeComponent
    prose_mirror_node = {
      "type" => "folioTiptapNode",
      "attrs" => {
        "type" => "unknown",
        "data" => {
          "title" => "UI Component Test",
          "text" => "Testing the UI card component rendering"
        }
      }
    }

    assert_raises(ArgumentError) do
      render_inline(Folio::Tiptap::Content::FolioTiptapNodeComponent.new(record: build_mock_record, prose_mirror_node:, tiptap_content_information:))
    end
  end

  def test_component_handles_missing_node_type
    prose_mirror_node = {
      "type" => "folioTiptapNode",
      "attrs" => {
        "data" => {
          "title" => "Missing Type Test",
          "text" => "Testing missing node type"
        }
      }
    }

    assert_raises(ActionController::ParameterMissing, "Node type is required but was not provided") do
      render_inline(Folio::Tiptap::Content::FolioTiptapNodeComponent.new(record: build_mock_record, prose_mirror_node:, tiptap_content_information:))
    end
  end

  def test_component_handles_blank_node_type
    prose_mirror_node = {
      "type" => "folioTiptapNode",
      "attrs" => {
        "type" => "",
        "data" => {
          "title" => "Blank Type Test",
          "text" => "Testing blank node type"
        }
      }
    }

    assert_raises(ActionController::ParameterMissing, "Node type is required but was not provided") do
      render_inline(Folio::Tiptap::Content::FolioTiptapNodeComponent.new(record: build_mock_record, prose_mirror_node:, tiptap_content_information:))
    end
  end

  def test_component_handles_nil_node_type
    prose_mirror_node = {
      "type" => "folioTiptapNode",
      "attrs" => {
        "type" => nil,
        "data" => {
          "title" => "Nil Type Test",
          "text" => "Testing nil node type"
        }
      }
    }

    assert_raises(ActionController::ParameterMissing, "Node type is required but was not provided") do
      render_inline(Folio::Tiptap::Content::FolioTiptapNodeComponent.new(record: build_mock_record, prose_mirror_node:, tiptap_content_information:))
    end
  end

  def test_component_handles_node_type_excluded_by_config
    prose_mirror_node = {
      "type" => "folioTiptapNode",
      "attrs" => {
        "type" => "Dummy::Tiptap::Node::Card",
        "data" => {
          "title" => "Excluded Type Test",
          "text" => "Testing node type excluded by config"
        }
      }
    }

    record = build_mock_record

    # Mock the tiptap_config to exclude all node types
    def record.tiptap_config
      @config ||= Folio::Tiptap::Config.new(node_names: [])
    end

    assert_raises(ArgumentError, "Node type 'Dummy::Tiptap::Node::Card' is not supported. Allowed types: ") do
      render_inline(Folio::Tiptap::Content::FolioTiptapNodeComponent.new(record: record, prose_mirror_node:, tiptap_content_information: tiptap_content_information(record: record)))
    end
  end

  private
    def build_mock_record
      Folio::Page.new
    end
end
