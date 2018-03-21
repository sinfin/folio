# frozen_string_literal: true

module Folio
  class Console::FilesController < Console::BaseController
    before_action :find_files, only: [:index]
    before_action :find_file, except: [:index, :create]

    before_action do
      if @file.present?
        type = @file.is_a?(Image) ? 'image' : 'document'
      else
        type = params[:type]
      end

      klass = type == 'image' ? Image : ::Folio::File

      add_breadcrumb klass.model_name.human(count: 2),
                     console_files_path(type: type)
    end

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

    def create
      @file = ::Folio::File.create!(file_params)
      render json: { file: FileSerializer.new(@file) },
             location: console_files_path
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
      p = params.require(:file).permit(:tag_list, :type, file: [])
      # redactor 3 ¯\_(ツ)_/¯
      if p[:file].is_a?(Array)
        p[:file] = p[:file].first
      end
      p
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
