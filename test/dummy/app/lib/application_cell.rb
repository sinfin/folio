# frozen_string_literal: true

class ApplicationCell < Folio::ApplicationCell
  def icon(key, opts = {})
    cell("dummy/ui/icon", key, opts)
  end

  if ::Rails.env.test?
    include Dummy::CurrentMethods

    # for simple cell tests we pass it in options, not doing `sign_in user`
    def current_user
      get_from_options_or_controller(:current_user)
    end

    def user_signed_in?
      get_from_options_or_controller(:user_signed_in?)
    end

    def get_from_options_or_controller(method_sym)
      if options.has_key?(method_sym)
        options[method_sym]
      else
        begin
          controller.try(method_sym)
        rescue Devise::MissingWarden
          nil
        end
      end
    end
  else
    %i[
      current_user
      user_signed_in?
      current_header_menu
      current_footer_menu
    ].each do |name|
      define_method(name) do
        controller.try(name)
      end
    end

    def current_page_singleton(klass, fail_on_missing: false)
      controller.try(:current_page_singleton, klass, fail_on_missing:)
    end
  end
end
