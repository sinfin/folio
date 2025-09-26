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
      dropdowns
      file_placements_multi_picker_fields
      in_place_inputs
      modals
      tabs
      tooltips
      warning_ribbons
    ].sort

    @inputs = %i[
      autocomplete
      date_time
      url
      rich_text
      tiptap
    ].sort
  end

  def in_place_inputs
    @page = Folio::Page.first

    @autocomplete_url = folio.url_for([:field,
                                       :console,
                                       :api,
                                       :autocomplete,
                                       klass: @page.class.to_s,
                                       field: :title,
                                       only_path: true])
  end

  def ajax_inputs
    @page = Folio::Page.first
  end

  def update_ajax_inputs
    unless Rails.env.development?
      raise ActionController::BadRequest.new("Can only do this in development")
    end

    @page = Folio::Page.first

    permitted = params.permit(:title,
                              :meta_title,
                              :meta_description)

    @page.update!(permitted)

    h = {}

    permitted.keys.each do |k|
      h[k] = @page.send(k)
    end

    render json: { data: h }
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

    @buttons_model_for_notifications_form = [
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

    @buttons_model_for_form_modals = [
      {
        variant: :info,
        label: "Folio::Current.user edit",
        form_modal: url_for([:edit, :console, Folio::Current.user]),
      },
      {
        variant: :info,
        label: "Folio::Current.user edit custom title",
        form_modal: url_for([:edit, :console, Folio::Current.user]),
        form_modal_title: "custom title",
      },
    ]
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
      flash.now[variant] = "#{variant.to_s.capitalize} #{@lorem_ipsum[0..15]} <a href=\"#{request.path}\">#{@lorem_ipsum[16..21]}</a> #{@lorem_ipsum[22..44]}.".html_safe
    end

    @buttons_model = [
      { variant: :success, label: "Add success flash", onclick: "window.FolioConsole.Ui.Flash.flash({ content: 'New success message!', variant: 'success' })" },
      { variant: :info, label: "Add info flash", onclick: "window.FolioConsole.Ui.Flash.flash({ content: 'New info message!', variant: 'info' })" },
      { variant: :warning, label: "Add warning flash", onclick: "window.FolioConsole.Ui.Flash.flash({ content: 'New warning message!', variant: 'warning' })" },
      { variant: :danger, label: "Add danger flash", onclick: "window.FolioConsole.Ui.Flash.flash({ content: 'New danger message!', variant: 'danger' })" },
      { variant: :info, loader: true, label: "Add loader flash", onclick: "window.FolioConsole.Ui.Flash.flash({ content: 'New loader message!', variant: 'loader' })" },
    ]
  end

  def input_date_time
  end

  def input_url
  end

  def input_autocomplete
    @page = Folio::Page.first
    @autocomplete_collection = %w[dog cat mouse rat horse cow pig sheep goat chicken duck turkey]
  end

  def dropdowns
    @links = [
      { label: "First", href: dropdowns_console_ui_path, icon: :plus_circle_multiple_outline },
      { label: "Second", href: dropdowns_console_ui_path, icon: :alert },
      { label: "Third", href: dropdowns_console_ui_path, icon: :archive, icon_options: { class: "text-danger" } },
    ]
  end

  def file_placements_multi_picker_fields
    @page = Folio::Page.first
  end

  def update_file_placements_multi_picker_fields
    if Rails.env.production?
      redirect_to file_placements_multi_picker_fields_console_ui_path, alert: "Don't do that in production"
      return
    end

    @page = Folio::Page.first

    if @page.update(params.require(:page).permit(*file_placements_strong_params))
      redirect_to file_placements_multi_picker_fields_console_ui_path, success: "Updated placements"
    else
      render :file_placements_multi_picker_fields
    end
  end

  private
    def only_allow_superadmins
      if Folio::Current.user.superadmin?
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
