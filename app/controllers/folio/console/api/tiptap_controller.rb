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
    @nodes_hash = {}

    params.require(:nodes).each do |node_attrs|
      @nodes_hash[node_attrs[:unique_id]] = { node: Folio::Tiptap::Node.new_from_params(node_attrs[:attrs]) }
    rescue StandardError => e
      @nodes_hash[node_attrs[:unique_id]] = { error: e }
    end

    render layout: false
  end

  def paste
    pasted_string = params.require(:pasted_string)
    node_type = params.require(:tiptap_node_type)

    node_klass = node_type.safe_constantize

    unless node_klass && node_klass < Folio::Tiptap::Node
      return render json: { error: "Invalid node type" }, status: :bad_request
    end

    paste_config = node_klass.tiptap_config[:paste]

    unless paste_config
      return render json: { error: "Node type does not have paste configuration" }, status: :unprocessable_entity
    end

    pattern = paste_config[:pattern]
    lambda_proc = paste_config[:lambda]

    unless pattern.match?(pasted_string)
      return render json: { error: "Paste string does not match pattern" }, status: :unprocessable_entity
    end

    node = lambda_proc.call(pasted_string)

    unless node
      return render json: { error: "Failed to create node from pasted string" }, status: :unprocessable_entity
    end

    render json: {
      data: { tiptap_node: node.to_tiptap_node_hash },
    }
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
