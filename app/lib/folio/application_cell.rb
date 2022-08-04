# frozen_string_literal: true

class Folio::ApplicationCell < Cell::ViewModel
  include ::Cell::Translation
  include ActionView::Helpers::TranslationHelper
  include Folio::CstypoHelper

  self.view_paths << "#{Folio::Engine.root}/app/cells"

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
  rescue NoMethodError, ActionController::UrlGenerationError
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
      rescue NoMethodError, ActionController::UrlGenerationError
        controller.main_app.send(menu_item.rails_path)
      end
    end
  end

  def togglable_fields(f, key, label: nil, &block)
    content_tag(:div, class: "f-togglable-fields") do
      concat(f.check_box(key, class: "f-togglable-fields__input"))

      if label.nil?
        concat(f.label(key, class: "f-togglable-fields__label"))
      else
        concat(f.label(key, label, class: "f-togglable-fields__label"))
      end

      concat(content_tag(:div, class: "f-togglable-fields__content", &block))
    end
  end

  unless ::Rails.application.config.folio_site_is_a_singleton
    def t(str, **options)
      if str.starts_with?(".")
        super(str.gsub(/\A\./, ".#{current_site.i18n_key_base}."), **options, default: super)
      else
        super
      end
    end
  end
end
