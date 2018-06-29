# frozen_string_literal: true

module Folio
  class Console::ImagesController < Console::BaseController
    include Console::FileControllerBase
    add_breadcrumb Image.model_name.human(count: 2), :console_images_path

    private

      def index_path
        console_images_path
      end

      def find_files
        @files = Image.ordered
      end
  end
end
