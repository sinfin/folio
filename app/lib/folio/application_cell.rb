# frozen_string_literal: true

class Folio::ApplicationCell < Cell::ViewModel
  include ::Cell::Translation
  include ActionView::Helpers::TranslationHelper
  include Folio::CstypoHelper
  include Folio::IconHelper
  include Folio::ImageHelper
  include Folio::PriceHelper
  include Folio::StimulusHelper

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


  def image(placement, size, opts = {})
    folio_image(placement, size, opts)
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

  # same as in Folio::ApplicationControllerBase but using "options hacks"
  def can_now?(action, object = nil, site: nil)
    object ||= Folio::Current.site
    (Folio::Current.user || Folio::User.new).can_now_by_ability?(current_ability, action, object)
  end

  def current_ability
    get_from_options_or_current_or_controller(:current_ability)
  end

  def user_signed_in?
    get_from_options_or_current_or_controller(:user_signed_in?)
  end

  def get_from_options_or_current_or_controller(method_sym)
    if options.has_key?(method_sym)
      options[method_sym]
    else
      begin
        method_base = method_sym.to_s.gsub("current_", "")
        ::Folio::Current.try(method_base.to_sym) || controller.try(method_sym)
      rescue Devise::MissingWarden
        nil
      end
    end
  end
  alias_method :get_from_options_or_controller, :get_from_options_or_current_or_controller

  def render_view_component(component, rescue_lambda: nil)
    if view = context[:view] || context[:controller].try(:view_context)
      if rescue_lambda
        begin
          view.render(component)
        rescue StandardError => e
          rescue_lambda.call(e)
        end
      else
        view.render(component)
      end
    else
      fail "Missing both context[:view] and context[:controller] - cannot render_view_component"
    end
  end

  def current_user_with_test_fallback
    if ::Rails.env.test? && options[:current_user]
      options[:current_user]
    else
      Folio::Current.user
    end
  end
end
