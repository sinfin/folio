# frozen_string_literal: true

module Folio::Console::FileControllerBase
  extend ActiveSupport::Concern

  def index
  end

  private

    def file_params
      p = params.require(:file)
                .permit(:tag_list,
                        :type,
                        :file,
                        tags: [])

      if p[:tags].present? && p[:tag_list].blank?
        p[:tag_list] = p.delete(:tags).join(',')
      end

      p
    end
end
