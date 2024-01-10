# frozen_string_literal: true

class Dummy::UiController < ApplicationController
  before_action :only_allow_superadmins

  def show
    @actions = %i[
      alerts
      boolean_toggles
      buttons
      breadcrumbs
      embed
      forms
      icons
      images
      inputs
      modals
      pagination
      tabs
      typo
    ]
  end

  def buttons
    ary = [
      { variant: :primary, label: "Primary" },
      { variant: :secondary, label: "Secondary" },
      { variant: :tertiary, label: "Tertiary" },
      { variant: :success, label: "Success" },
      { variant: :info, label: "Info" },
      { variant: :warning, label: "Warning" },
      { variant: :danger, label: "Danger" },
      { variant: :info, loader: true, label: "Loader" },
    ]

    @buttons_model = {}

    {
      "Regular" => {},
      "Small" => { size: :sm },
      "Large" => { size: :lg },
      "Disabled" => { disabled: true },
    }.each do |title, h|
      @buttons_model[title] = [
        ary.map { |b| b.merge(h) },
        ary.map { |b| b.merge(h).merge(icon: :alert_triangle) },
        ary.map { |b| b.merge(h).merge(icon: :alert_triangle, right_icon: :alert_triangle) },
        ary.map { |b| b.merge(h).merge(icon: :alert_triangle, label: nil) },
      ]
    end
  end

  def alerts
    @hide_flash_messages = true

    %i[
      dark
      notice
      warning
      success
      alert
      loader
    ].each do |variant|
      flash.now[variant] = "#{variant.to_s.capitalize} #{@lorem_ipsum[0..44]}."
    end

    @buttons_model = [
      { variant: :dark, label: "Add dark flash", onclick: "window.Dummy.Ui.Flash.flash({ content: 'New dark message!', variant: 'dark' })" },
      { variant: :info, label: "Add info flash", onclick: "window.Dummy.Ui.Flash.flash({ content: 'New info message!', variant: 'info' })" },
      { variant: :warning, label: "Add warning flash", onclick: "window.Dummy.Ui.Flash.flash({ content: 'New warning message!', variant: 'warning' })" },
      { variant: :success, label: "Add success flash", onclick: "window.Dummy.Ui.Flash.flash({ content: 'New success message!', variant: 'success' })" },
      { variant: :danger, label: "Add danger flash", onclick: "window.Dummy.Ui.Flash.flash({ content: 'New danger message!', variant: 'danger' })" },
      { variant: :info, loader: true, label: "Add loader flash", onclick: "window.Dummy.Ui.Flash.flash({ content: 'New loader message!', variant: 'loader' })" },
    ]
  end

  def pagination
    @pagy, _records = pagy(Dummy::Blog::Article, items: 1)
  end

  def images
    @image = Folio::File::Image.tagged_with("unsplash").first

    @variants = [
      { size: "100x100#" },
      { size: "100x100" },
      { size: "100x100", kwargs: { cover: true } },
      { size: "100x100", kwargs: { contain: true } },
      { size: "100x100#", kwargs: { lazy: false } },
      { size: "100x100#", kwargs: { round: true } },
      { size: "100x100#", kwargs: { hover_zoom: true } },
    ]
  end

  private
    def only_allow_superadmins
      authenticate_user!

      if can_now?(:display_ui)
        add_breadcrumb "UI", dummy_ui_path

        if action_name != "show"
          add_breadcrumb action_name.capitalize, send("#{action_name}_dummy_ui_path")
        end

        @lorem_ipsum = "ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
      else
        redirect_to root_path
      end
    end
end
