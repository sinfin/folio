require_dependency 'folio/application_controller'

module Folio
  class Console::FilesController < Console::BaseController
    before_action :find_file, except: [:index, :create, :new]
    respond_to :js, only: [:index, :create]

    def index
      @images = Image.page(current_page)
      @documents = Document.page(current_page)
      respond_with(@images) do |format|
        format.html { render }
        format.js { render json: @images }
      end
    end

    def new
      if params[:file_type] == 'image'
        @file = Image.new
      else
        @file = Document.new
      end
    end

    def create
      @file = Folio::File.create(file_params)
      respond_with @file, location: console_files_path
    end

    def update
      @file.update(file_params)
      respond_with @file, location: console_files_path
    end

    def destroy
      @file.destroy
      respond_with @file, location: console_files_path
    end

  private
    def find_file
      @file = Folio::File.find(params[:id])
    end

    def file_params
      params.require(:file).permit(:file, :tag_list, :type)
    end
  end
end
