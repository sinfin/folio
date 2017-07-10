require_dependency 'folio/application_controller'

module Folio
  class Console::NodesController < Console::BaseController
    before_action :find_node, except: [:index]

    def index
      @nodes = Folio::Node.arrange
    end

    def edit
    end

  private
    def find_node
      @node = Folio::Node.friendly.find(params[:id])
    end
  end
end
