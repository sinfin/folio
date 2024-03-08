# frozen_string_literal: true

class Folio::Console::UiController < Folio::Console::BaseController
  before_action :only_allow_superadmins

  def show
    @actions = %i[
      ajax_inputs
      alerts
      badges
      boolean_toggles
      buttons
      modals
      tabs
      warning_ribbons
    ].sort

    @inputs = %i[
      date_time
    ].sort
  end

  def ajax_inputs
    @page = Folio::Page.last
  end

  def update_ajax_inputs
    unless Rails.env.development?
      raise ActionController::BadRequest.new("Can only do this in development")
    end

    name = params.require(:name)

    if %w[title meta_title meta_description].exclude?(name)
      raise ActionController::BadRequest.new("Invalid name #{name}")
    end

    value = params.require(:value)

    @page = Folio::Page.last
    @page.update!(name => value)

    render json: { data: { value: } }
  end

  def tabs
    @links_tabs = [
      { label: "First tab", href: tabs_console_ui_path(tab: 1), active: %w[2 3].exclude?(params[:tab]) },
      { label: "Second tab", href: tabs_console_ui_path(tab: 2), active: params[:tab] == "2" },
      { label: "Third tab", href: tabs_console_ui_path(tab: 3), active: params[:tab] == "3" },
    ]

    @javascript_tabs = [
      { label: "First tab", key: "first-tab", active: true },
      { label: "Second tab", key: "second-tab" },
      { label: "Third tab", key: "third-tab" },
    ]
  end

  def warning_ribbons
  end

  def buttons
    @buttons_model = [
      { variant: :primary, label: "Primary" },
      { variant: :secondary, label: "Secondary" },
      { variant: :tertiary, label: "Tertiary" },
      { variant: :success, label: "Success" },
      { variant: :info, label: "Info" },
      { variant: :warning, label: "Warning" },
      { variant: :danger, label: "Danger" },
      { variant: :info, loader: true, label: "Loader" },
    ]
  end

  def modals
    @button_model_for_notifications_message = {
      variant: :info,
      label: "Info modal",
      notification_modal: {
        title: "info title",
        body: "<p>Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.</p>",
        cancel: true,
      }
    }

    @button_model_for_notifications_form = [
      {
        variant: :info,
        label: "Modal with submit",
        notification_modal: {
          title: "this modal",
          body: "<p>can submit the form</p>",
          cancel: true,
          submit: true,
        }
      },
      {
        variant: :primary,
        label: "Submit",
        type: :submit,
      }
    ]

    @button_model_for_form_modal = {
      variant: :info,
      label: "current_user edit",
      form_modal: url_for([:edit, :console, current_user]),
    }
  end

  def alerts
    @hide_flash_messages = true

    %i[
      success
      notice
      warning
      alert
      error
      loader
    ].each do |variant|
      flash.now[variant] = "#{variant.to_s.capitalize} #{@lorem_ipsum[0..44]}."
    end

    @buttons_model = [
      { variant: :success, label: "Add success flash", onclick: "window.FolioConsole.Flash.flash({ content: 'New success message!', variant: 'success' })" },
      { variant: :info, label: "Add info flash", onclick: "window.FolioConsole.Flash.flash({ content: 'New info message!', variant: 'info' })" },
      { variant: :warning, label: "Add warning flash", onclick: "window.FolioConsole.Flash.flash({ content: 'New warning message!', variant: 'warning' })" },
      { variant: :danger, label: "Add danger flash", onclick: "window.FolioConsole.Flash.flash({ content: 'New danger message!', variant: 'danger' })" },
      { variant: :info, loader: true, label: "Add loader flash", onclick: "window.FolioConsole.Flash.flash({ content: 'New loader message!', variant: 'loader' })" },
    ]
  end

  def input_date_time
  end

  private
    def only_allow_superadmins
      if current_user.superadmin?
        add_breadcrumb "UI", console_ui_path

        if action_name != "show"
          add_breadcrumb action_name.capitalize, send("#{action_name}_console_ui_path")
        end

        @lorem_ipsum = "ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
      else
        redirect_to console_root_path
      end
    end
end
