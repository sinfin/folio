# frozen_string_literal: true

module Folio::Console::FileControllerBase
  extend ActiveSupport::Concern

  included do
    before_action :find_file, except: [:index, :create, :tag]

    respond_to :json, only: [:index, :create]
  end

  def index
    respond_to do |format|
      format.html
      format.json do
        files = find_files

        if filter_params.present?
          files = files.filter_by_params(filter_params)
        end

        pagination, records = pagy(files, items: 60)
        meta = meta_from_pagy(pagination)

        render json: json_from_records(records, meta: meta)
      end
    end
  end

  def create
    @file = Folio::File.new(file_params)
    if @file.save
      render json: Folio::FileSerializer.new(@file),
             location: edit_path(@file)
    else
      render json: { error: @file.errors.full_messages.first, status: 422 },
             location: edit_path(@file),
             status: 422
    end
  end

  def update
    if @file.update(file_params)
      respond_with(@file, location: index_path) do |format|
        format.html
        format.json { render json: Folio::FileSerializer.new(@file) }
      end
    else
      respond_with(@file, location: index_path) do |format|
        format.html
        format.json do
          render json: { error: @file.errors.full_messages.first, status: 422 },
                 location: index_path,
                 status: 422
        end
      end
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
      Folio::FileSerializer.new(file, root: false).serializable_hash
    end.to_json

    render plain: json
  end

  private

    def find_file
      @file = Folio::File.find(params[:id])
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
      if file.is_a?(Folio::Image)
        console_images_path
      else
        console_documents_path
      end
    end

    def json_from_records(models, meta: nil)
      data = models.map do |file|
        Folio::FileSerializer.new(file, root: false).serializable_hash
      end

      {
        data: data,
        meta: meta,
      }
    end

    def meta_from_pagy(pagy_data)
      {
        page: pagy_data.page,
        pages: pagy_data.pages,
        from: pagy_data.from,
        to: pagy_data.to,
        count: pagy_data.count,
      }
    end

    def filter_params
      params.permit(:by_name, :by_tags, :by_placement)
    end
end
