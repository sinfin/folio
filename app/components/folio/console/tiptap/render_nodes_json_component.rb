# frozen_string_literal: true

class Folio::Console::Tiptap::RenderNodesJsonComponent < Folio::Console::ApplicationComponent
  def initialize(nodes_hash:)
    @nodes_hash = nodes_hash
  end

  def components_array
    runner = []

    @nodes_hash.each do |unique_id, node|
      runner << {
        "unique_id" => unique_id,
        "html" => render_node_component(node),
      }
    end

    runner
  end

  def render_node_component(node)
    if node.valid?
      component = node.class.view_component_class.new(node:)

      capture { render(component) }
    else
      capture { render(Folio::Console::Tiptap::InvalidNodeComponent.new(node:)) }
    end
  rescue StandardError => error
    capture { render(Folio::Console::Tiptap::InvalidNodeComponent.new(node:, error:)) }
  end

  def call
    { "data" => components_array }.to_json.html_safe
  end
end
