# frozen_string_literal: true

class Folio::Console::ImagesController < Folio::Console::BaseController
  include Folio::Console::FileControllerBase
  add_breadcrumb(Folio::Image.model_name.human(count: 2),
                 :console_images_path)

  private

    def index_path
      console_images_path
    end

    def find_files
      Folio::Image.ordered
    end
end
