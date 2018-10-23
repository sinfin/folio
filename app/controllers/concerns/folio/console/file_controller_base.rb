# frozen_string_literal: true

module Folio
  module Console
    module FileControllerBase
      extend ActiveSupport::Concern

      included do
        before_action :find_files, only: [:index]
        before_action :find_file, except: [:index, :create]

        respond_to :json, only: [:index, :create]
      end

      def index
        respond_with(@files) do |format|
          format.html
          format.json { render json: @files }
        end
      end

      def create
        @file = ::Folio::File.create!(file_params)
        render json: { file: FileSerializer.new(@file) },
               location: edit_path(@file)
      end

      def update
        @file.update(file_params)
        respond_with(@file, location: index_path) do |format|
          format.html
          format.json { render json: { file: FileSerializer.new(@file) } }
        end
      end

      def destroy
        @file.destroy
        respond_with @file, location: index_path
      end

      private

        def find_file
          @file = ::Folio::File.find(params[:id])
        end

        def file_params
          p = params.require(:file).permit(:tag_list, :type, :file, file: [])
          # redactor 3 ¯\_(ツ)_/¯
          if p[:file].is_a?(Array)
            p[:file] = p[:file].first
          end
          p
        end

        def index_path
          @files = ::Folio::File.ordered
        end

        def edit_path(file)
          if file.is_a?(Image)
            console_images_path
          else
            console_documents_path
          end
        end
    end
  end
end
