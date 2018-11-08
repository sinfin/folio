# frozen_string_literal: true

module Folio
  module Console::FormsHelper
    def console_form_atoms(f)
      render partial: 'atoms', locals: { f: f }
    end

    def console_form_fields_for(f, relation)
      render partial: 'folio/console/partials/simple_fields_for',
             locals: { f: f, relation: relation }
    end

    def translated_inputs(f, key, *args)
      cell('folio/console/translated_inputs', f: f, key: key, args: args).show.html_safe
    end
  end
end
