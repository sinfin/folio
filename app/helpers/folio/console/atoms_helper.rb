# frozen_string_literal: true

module Folio
  module Console::AtomsHelper
    def console_form_atoms(f)
      render partial: 'atoms', locals: { f: f }
    end
  end
end
