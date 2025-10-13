# frozen_string_literal: true

# syntactic sugar for cells
module Folio
  module Console::CellsHelper
    def nested_model_controls(model, options = {})
      cell("folio/console/nested_model_controls", model, options).show.html_safe
    end

    def single_image_select(f, attr_name = :file)
      single_file_select(f, attr_name, as: :image)
    end

    def single_video_select(f, attr_name = :file)
      single_file_select(f, attr_name, as: :video)
    end

    def single_document_select(f, attr_name = :file)
      single_file_select(f, attr_name, as: :document)
    end

    def single_file_select(f, attr_name = :file, as: :file)
      cell("folio/console/single_file_select", f, attr_name:,
                                                  as:).show.html_safe
    end

    def show_header(model, opts = {})
      cell("folio/console/show/header", model, opts).show.html_safe
    end

    def form_header(f, opts = {}, &block)
      if block_given?
        opts[:right] = capture(&block)
      end

      render(Folio::Console::Form::HeaderComponent.new(model: f,
                                                      title: opts[:title],
                                                      title_class_name: opts[:title_class_name],
                                                      subtitle: opts[:subtitle],
                                                      left: opts[:left],
                                                      right: opts[:right],
                                                      sti_badge: opts[:sti_badge],
                                                      tabs: opts[:tabs],
                                                      hide_fix_error_btn: opts.slice(:hide_fix_error_btn)))
    end
  end
end
