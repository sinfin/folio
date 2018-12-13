# frozen_string_literal: true

class FolioCell < Cell::ViewModel
  include ::Cell::Translation
  include ActionView::Helpers::TranslationHelper

  self.view_paths << "#{Folio::Engine.root}/app/cells"

  # https://github.com/trailblazer/cells-rails/issues/23#issuecomment-310537752
  def protect_against_forgery?
    controller.send(:protect_against_forgery?)
  end

  def html_safe_fields_for(f, key, objects = nil, &block)
    f.simple_fields_for key, objects do |subfields|
      (yield subfields).html_safe
    end
  end
end
