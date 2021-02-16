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

  def register_button_class_name
    "btn btn-outline-primary"
  end

  def register_button
    link_to(t("folio.devise.register_button"),
            controller.new_registration_path(resource_name),
            class: register_button_class_name)
  end

  def submit_button(f, label)
    content_tag(:div, class: "f-devise__submit-wrap") do
      f.button :submit, label, class: "f-devise__submit-btn"
    end
  end

  def email_input(f, opts = {})
    f.input :email, opts.merge(input_html: {
                                autofocus: true,
                                autocomplete: "email",
                                value: f.object.email.presence || "@"
                              })
  end

  def password_input(f, field, opts = {})
    cell("folio/devise/password_input",
         f,
         opts.merge(field: field))
  end

  def attribute_input(f, field, opts = {})
    f.input field, opts.merge(input_html: {
      value: f.object.send(field).presence || params[resource_name].try(:[], field)
    })
  end
end
