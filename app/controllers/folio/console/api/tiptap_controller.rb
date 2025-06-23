# frozen_string_literal: true

class Folio::Console::Api::TiptapController < Folio::Console::Api::BaseController
  before_action :initialize_node

  def edit_node
    render_component_json(Folio::Console::Tiptap::Overlay::FormComponent.new(node: @node))
  end

  def save_node
    @node.assign_attributes_from_params(params)

    if @node.valid?
      render json: {
        data: { tiptap_node: @node.to_tiptap_node_hash },
        meta: { tiptap_node_valid: true }
      }
    else
      render_component_json(Folio::Console::Tiptap::Overlay::FormComponent.new(node: @node))
    end
  end

  private
    def initialize_node
      node_klass = params.require(:tiptap_node_type).safe_constantize

      if node_klass < Folio::Tiptap::Node
        @node = node_klass.new
      else
        fail ArgumentError, "Invalid Tiptap node type: #{params[:tiptap_node_type]}"
      end
    end
end
