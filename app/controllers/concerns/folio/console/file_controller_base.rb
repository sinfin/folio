# frozen_string_literal: true

module Folio
  module Console
    module FileControllerBase
      extend ActiveSupport::Concern

      included do
        before_action :find_file, except: [:index, :create, :tag]

        respond_to :json, only: [:index, :create]
      end

      def index
        respond_to do |format|
          format.html
          format.json do
            cache_key = [self.class.to_s, ::Folio::File.maximum(:updated_at)]

            files_json = Rails.cache.fetch(cache_key, expires_in: 1.day) do
              find_files.map do |file|
                ::Folio::FileSerializer.new(file).serializable_hash
              end.to_json
            end

            render plain: files_json
          end
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

      def tag
        tag_params = params.permit(file_ids: [],
                                   tags: [])

        @files = Folio::File.where(id: tag_params[:file_ids])

        Folio::File.transaction do
          @files.each { |f| f.update!(tag_list: tag_params[:tags]) }
        end

        json = @files.map do |file|
          ::Folio::FileSerializer.new(file).serializable_hash
        end.to_json

        render plain: json
      end

      private

        def find_file
          @file = ::Folio::File.find(params[:id])
        end

        def find_files
        end

        def file_params
          p = params.require(:file).permit(:tag_list,
                                           :type,
                                           :file,
                                           file: [],
                                           tags: [])
          # redactor 3 ¯\_(ツ)_/¯
          if p[:file].is_a?(Array)
            p[:file] = p[:file].first
          end

          if p[:tags].present? && p[:tag_list].blank?
            p[:tag_list] = p.delete(:tags).join(',')
          end

          p
        end

        def index_path
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
