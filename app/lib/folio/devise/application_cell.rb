# frozen_string_literal: true

class Folio::Devise::ApplicationCell < Folio::ApplicationCell
  include SimpleForm::ActionViewExtensions::FormHelper

  def title(label = nil)
    content_tag(model && model[:modal] ? :div : :h1,
                label.presence || t(".title"),
                class: "h1 f-devise__title")
  end

  def resource
    model[:resource]
  end

  def resource_name
    model[:resource_name]
  end

  def forgotten_password_link
    link_to(t("folio.devise.forgotten_password_link"),
            controller.new_password_path(resource_name),
            class: "f-devise__under-submit-link")
  end

  def sign_in_link
    t("folio.devise.sign_in_link",
      href: controller.new_session_path(resource_name))
  end

  def invite_button_class_name
    "btn btn-outline-primary"
  end

  def invite_button
    link_to(t("folio.devise.invite_button"),
            controller.new_invitation_path(resource_name),
            class: "f-devise-modal-aware-link #{invite_button_class_name}")
  end

  def submit_button(f, label)
    content_tag(:div, class: "f-devise__submit-wrap") do
      f.button :submit, label, class: "f-devise__submit-btn #{submit_button_class_names}"
    end
  end

  def submit_button_class_names
    ""
  end

  def email_input(f, opts = {})
    f.input :email, opts.merge(required: true,
                               input_html: {
                                autofocus: opts[:autofocus].nil? ? true : opts[:autofocus],
                                autocomplete: "email",
                                value: f.object.email.presence || "@",
                                id: nil,
                              })
  end

  def phone_input(f, opts = {})
    f.input :phone, opts.merge(required: true,
                               input_html: {
                                autocomplete: "phone",
                                id: nil,
                              })
  end

  def password_input(f, field, opts = {})
    cell("folio/devise/password_input",
         f,
         opts.merge(field:))
  end

  def attribute_input(f, field, opts = {})
    f.input field, opts.merge(input_html: {
      value: f.object.send(field).presence || params[resource_name].try(:[], field),
      id: nil,
    })
  end

  def omniauth_button_class_name
    "btn btn-outline-primary btn-xs-block"
  end

  def invitations_perex
  end

  def invitations_gdpr_content
    content_tag(:p, t(".gdpr_content"))
  end

  def omniauth_above?
    true
  end

  def omniauth_button_label(key)
    t("folio.devise.omniauth.providers.#{key}")
  end

  def omniauth_button_icon(key)
    cell("folio/devise/omniauth/icon", key, size: 24)
  end

  def application_namespace
    ::Rails.application.class.name.deconstantize
  end

  def application_namespace_path
    application_namespace.underscore
  end
end
