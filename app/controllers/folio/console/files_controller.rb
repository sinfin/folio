# frozen_string_literal: true

module Folio
  class Console::FilesController < Console::BaseController
    before_action :find_file, except: [:index, :create, :new]
    respond_to :json, only: [:index, :create]

    add_breadcrumb(I18n.t('folio.console.files.index.title'),
                   :console_files_path)

    def index
      if params[:type] == 'document'
        @files = Document.all
      else
        @files = Image.all
      end

      if !params[:by_tag].blank?
        @files = @files.filter(filter_params)
      end

      @files = @files.page(current_page)

      if request.format == :json
        @files = @files.per(11)
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
      @file = File.create(file_params)
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
      @file = File.find(params[:id])
    end

    def filter_params
      params.permit(:by_tag)
    end


    def file_params
      params.require(:file).permit(:file, :tag_list, :type)
    end
  end
end
