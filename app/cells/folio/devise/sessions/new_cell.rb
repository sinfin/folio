# frozen_string_literal: true

class Folio::Devise::Sessions::NewCell < Folio::Devise::ApplicationCell
  def form(&block)
    opts = {
      url: controller.session_path(resource_name),
      as: resource_name,
      html: {
        class: model[:modal] ? "f-devise-modal__form" : nil,
        id: nil,
        "data-failure" => t(".failure"),
      },
    }

    simple_form_for(resource, opts, &block)
  end

  def dev_login?
    ::Rails.env.development? && dev_login_credentials.present?
  end

  def dev_login_email
    dev_login_credentials[:email].to_s
  end

  def dev_login_password
    dev_login_credentials[:password].to_s
  end

  private
    def dev_login_credentials
      config = ::Rails.application.config
      return nil unless config.respond_to?(:folio_devise_dev_login_credentials)
      config.folio_devise_dev_login_credentials
    end
end
