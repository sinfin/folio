# frozen_string_literal: true

class Folio::Console::Tiptap::RenderNodesJsonComponent < Folio::Console::ApplicationComponent
  def initialize(nodes_hash:)
    @nodes_hash = nodes_hash
  end

  def components_array
    runner = []

    @nodes_hash.each do |unique_id, hash|
      if hash[:node]
        runner << render_node_component(unique_id:, node: hash[:node])
      elsif hash[:error]
        runner << render_invalid_or_error(unique_id:, node: nil, error: hash[:error])
      else
        fail "Neither :node nor :error present in nodes_hash for unique_id #{unique_id}"
      end
    end

    runner
  end

  def render_node_component(unique_id:, node:)
    if node.valid?
      tiptap_content_information = {
        record: node,
        attribute: :tiptap_content,
        depth: 0,
        root_node_count: 0,
        editor_preview: true
      }
      component = node.class.view_component_class.new(node:, tiptap_content_information:)

      {
        "unique_id" => unique_id,
        "html" => capture { render(component) },
      }
    else
      render_invalid_or_error(unique_id:, node: node)
    end
  rescue StandardError => error
    render_invalid_or_error(unique_id:, node: node, error: error)
  end

  def call
    { "data" => components_array }.to_json.html_safe
  end

  def render_invalid_or_error(unique_id:, node:, error: nil)
    if error && error.message
      {
        "unique_id" => unique_id,
        "error_message" => error.message,
        "invalid" => true,
      }
    else
      {
        "unique_id" => unique_id,
        "invalid" => true
      }
    end
  end
end
