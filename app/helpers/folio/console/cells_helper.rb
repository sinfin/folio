# frozen_string_literal: true

# syntactic sugar for cells
module Folio
  module Console::CellsHelper
    def boolean_toggle(model, attribute, options = {})
      opts = options.merge(attribute: attribute)
      cell('folio/console/boolean_toggle', model, opts).show
                                                       .try(:html_safe)
    end

    def nested_model_controls(model, options = {})
      cell('folio/console/nested_model_controls', model, options).show.html_safe
    end

    def index_position_buttons(model, options = {})
      cell('folio/console/index_position_buttons', model,
                                                   options).show.html_safe
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
      cell('folio/console/single_file_select', f, attr_name: attr_name,
                                                  as: as).show.html_safe
    end

    def form_footer(f, back_path = nil, destroy: nil)
      cell('folio/console/form_footer', f, back_path: back_path,
                                           destroy: destroy).show.html_safe
    end
  end
end
