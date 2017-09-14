require_dependency 'folio/application_controller'

module Folio
  class Console::FilesController < Console::BaseController
    before_action :find_file, except: [:index, :create, :new]
    respond_to :json, only: [:index, :create]

    def index
      if !params[:by_tag].blank?
        @images = Image.filter(filter_params).page(current_page)
        @documents = Document.filter(filter_params)
      else
        @images = Image.page(current_page)
        @documents = Document.all
      end

      if params[:type] == 'image'
        render json: @images.page(current_page)
      elsif params[:type] == 'document'
        render json: @documents.page(current_page)
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

    def filter_params
      params.permit(:by_tag)
    end


    def file_params
      params.require(:file).permit(:file, :tag_list, :type)
    end
  end
end
