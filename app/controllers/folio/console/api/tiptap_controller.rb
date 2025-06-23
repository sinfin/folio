# frozen_string_literal: true

class Folio::Console::Api::TiptapController < Folio::Console::Api::BaseController
  before_action :initialize_node, only: %i[edit_node save_node]

  def edit_node
    render_component_json(Folio::Console::Tiptap::Overlay::FormComponent.new(node: @node))
  end

  def save_node
    if @node.valid?
      render json: {
        data: { tiptap_node: @node.to_tiptap_node_hash },
        meta: { tiptap_node_valid: true }
      }
    else
      render_component_json(Folio::Console::Tiptap::Overlay::FormComponent.new(node: @node))
    end
  end

  def render_nodes
    @components = []
    @index = 0

    params.require(:nodes).each do |node_attrs|
      node = Folio::Tiptap::Node.new_from_attrs(node_attrs[:attrs])
      component = node.class.view_component_class.new(node:)
      @components << [node_attrs[:unique_id], component]
    end

    render layout: false
  end

  private
    def initialize_node
      tiptap_node_attrs = params.require(:tiptap_node_attrs)
      node_klass = tiptap_node_attrs.require(:type).safe_constantize

      if node_klass < Folio::Tiptap::Node
        @node = node_klass.new
        @node.assign_attributes_from_param_attrs(tiptap_node_attrs)
      else
        fail ArgumentError, "Invalid Tiptap node type: #{params[:tiptap_node_type]}"
      end
    end
end
