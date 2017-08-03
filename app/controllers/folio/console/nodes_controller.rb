require_dependency 'folio/application_controller'

module Folio
  class Console::NodesController < Console::BaseController
    before_action :find_node, except: [:index, :create, :new]

    def index
      @nodes = Folio::Node.arrange
    end

    def new
      @node = Folio::Node.new
    end

    def create
      @node = Folio::Node.create(node_params)
      respond_with @node, location: console_nodes_path
    end

    def update
      @node.update(node_params)
      respond_with @node, location: console_nodes_path
    end

    def destroy
      @node.destroy
      respond_with @node, location: console_nodes_path
    end

  private
    def find_node
      @node = Folio::Node.friendly.find(params[:id])
    end

    def node_params
      p = params.require(:node).permit(:title, :slug, :perex, :content, :meta_title, :meta_description, :code, :type, :featured, :published, :published_at, :locale, :parent_id, file_placements_attributes: [:id, :caption, :file_id, :_destroy])
      p.delete(:password) unless p[:password].present?
      p
    end
  end
end
