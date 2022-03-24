# frozen_string_literal: true

class Folio::ApplicationCell < Cell::ViewModel
  include ::Cell::Translation
  include ActionView::Helpers::TranslationHelper
  include Folio::CstypoHelper

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
        if try(key) || options[key]
          safe_key = key.to_s.tr("_", "-").delete("?")
          class_names << "#{base}--#{safe_key}"
        end
      end

      class_names.join(" ")
    end
  end

  def url_for(options)
    controller.url_for(options)
  rescue NoMethodError
    controller.main_app.url_for(options)
  end

  def current_site
    controller.current_site
  end

  def image(placement, size, opts = {})
    cell("folio/image", placement, opts.merge(size:))
  end

  def menu_url_for(menu_item)
    if menu_item.url.present?
      menu_item.url
    elsif menu_item.eager_load_aware_target.present?
      url_for(menu_item.eager_load_aware_target)
    elsif menu_item.rails_path.present?
      begin
        controller.send(menu_item.rails_path)
      rescue NoMethodError
        controller.main_app.send(menu_item.rails_path)
      end
    end
  end
end
