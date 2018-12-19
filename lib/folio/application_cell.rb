# frozen_string_literal: true

class Folio::ApplicationCell < Cell::ViewModel
  include ::Cell::Translation
  include ActionView::Helpers::TranslationHelper

  self.view_paths << "#{Folio::Engine.root}/app/cells"

  # https://github.com/trailblazer/cells-rails/issues/23#issuecomment-310537752
  def protect_against_forgery?
    controller.send(:protect_against_forgery?)
  end

  def self.class_name(base, *keys)
    define_method :class_name do
      class_names = [base]
      class_names << options[:class_name] if options[:class_name]

      keys.each do |key|
        class_names << "#{base}--#{key.to_s.gsub('_', '-')}" if options[key]
      end

      class_names.join(' ')
    end
  end
end
