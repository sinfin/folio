# frozen_string_literal: true

class Folio::Console::ImagesController < Folio::Console::BaseController
  include Folio::Console::FileControllerBase
  add_breadcrumb(Folio::Image.model_name.human(count: 2),
                 :console_images_path)

  before_action { @klass = Folio::Image }

  private

    def index_path
      console_images_path
    end

    def find_files
      cache_key = ['folio', 'console', 'images', Folio::Image.maximum(:updated_at)]

      @files = Rails.cache.fetch(cache_key, expires_in: 1.day) do
        Folio::Image.ordered
                    .includes(:tags)
                    .includes(:file_placements)
                    .all
      end
    end
end
