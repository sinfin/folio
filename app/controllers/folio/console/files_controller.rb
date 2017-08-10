require_dependency 'folio/application_controller'

module Folio
  class Console::FilesController < Console::BaseController
    before_action :find_file, except: [:index, :create, :new]

    def index
      @images = Folio::Image.all
      @documents = Folio::Document.all
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
      if @file.save
        respond_to do |format|
          format.html { redirect_to action: :index }
          format.json { render json: { message: 'success' }, status: 200 }
        end
      else
        respond_to do |format|
          format.html { render action: :new }
          format.json { render json: { error: @file.errors.full_messages.join(',') }, status: 400 }
        end
      end
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
      params.require(:file).permit(:file, :type)
    end
  end
end
