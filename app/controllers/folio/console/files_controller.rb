require_dependency 'folio/application_controller'

module Folio
  class Console::FilesController < Console::BaseController
    before_action :find_file, except: [:index, :create, :new]

    def index
      @images = Folio::Image.all
      @documents = Folio::Document.all
    end

    def show
    end

    def new
    end

    def create
    end

    def edit
    end

    def update
    end

  private
    def find_file
      @node = Folio::File.find(params[:id])
    end
  end
end
