# frozen_string_literal: true

module Folio
  class Console::FilesController < Console::BaseController
    before_action :find_files, only: [:index]
    before_action :find_file, except: [:index, :create, :new]
    respond_to :json, only: [:index, :create]

    def index
      if !params[:by_tag].blank?
        @files = @files.filter(filter_params)
      end

      respond_with(@files) do |format|
        format.html
        format.json { render json: @files }
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
      @file = ::Folio::File.create(file_params)
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
      @file = ::Folio::File.find(params[:id])
    end

    def filter_params
      params.permit(:by_tag)
    end


    def file_params
      params.require(:file).permit(:file, :tag_list, :type)
    end

    def find_files
      case params[:type]
      when 'document'
        @files = Document.all

      when 'image'
        @files = Image.all

      else
        @files = ::Folio::File.all
      end
    end
  end
end
