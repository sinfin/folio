# frozen_string_literal: true

module Folio::Console::FileControllerBase
  extend ActiveSupport::Concern

  def edit
    render "folio/console/file/edit"
  end

  def show
    @file_for_modal = Folio::Console::FileSerializer.new(folio_console_record)
                                                    .serializable_hash[:data]
                                                    .to_json

    render index_view_name
  end

  private
    def file_params
      p = params.require(:file)
                .permit(:tag_list,
                        :type,
                        :file,
                        :author,
                        :description,
                        tags: [])

      if p[:tags].present? && p[:tag_list].blank?
        p[:tag_list] = p.delete(:tags).join(",")
      end

      p
    end

    # manually set method overriding default_actions
    def folio_console_params
      file_params
    end

    def folio_console_record_includes
      [:file_placements]
    end

    def index_view_name
      "folio/console/file/index"
    end
end
