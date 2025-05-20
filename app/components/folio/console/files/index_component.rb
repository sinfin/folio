# frozen_string_literal: true

class Folio::Console::Files::IndexComponent < Folio::Console::ApplicationComponent
  def initialize(file_klass:, files:, modal: false)
    @file_klass = file_klass
    @files = files
    @modal = modal
  end
end
