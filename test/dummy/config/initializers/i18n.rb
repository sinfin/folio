# frozen_string_literal: true

module I18n::Backend::Cells
  def load_translations(*filenames)
    return super(*filenames) if filenames.present?

    additional_cell_paths = [
      Dir[Folio::Engine.root.join("app", "cells", "**", "*.yml").to_s],
      Dir[Rails.root.join("app", "cells", "**", "*.yml").to_s]
    ]

    super(*(I18n.load_path + additional_cell_paths))
  end
end

I18n::Backend::Simple.include(I18n::Backend::Cells)
