# frozen_string_literal: true

class Dummy::UiController < ApplicationController
  before_action :only_allow_superadmins

  def show
    @actions = %i[
      alerts
      boolean_toggles
      breadcrumbs
      buttons
      documents
      chips
      clipboard
      embed
      forms
      hero
      icons
      images
      inputs
      modals
      pagination
      slide_lists
      tabs
      share
      topics
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
      { variant: :dark, label: "Add dark flash",
        onclick: "window.Dummy.Ui.Flash.flash({ content: 'New dark message!', variant: 'dark' })" },
      { variant: :info, label: "Add info flash",
        onclick: "window.Dummy.Ui.Flash.flash({ content: 'New info message!', variant: 'info' })" },
      { variant: :warning, label: "Add warning flash",
        onclick: "window.Dummy.Ui.Flash.flash({ content: 'New warning message!', variant: 'warning' })" },
      { variant: :success, label: "Add success flash",
        onclick: "window.Dummy.Ui.Flash.flash({ content: 'New success message!', variant: 'success' })" },
      { variant: :danger, label: "Add danger flash",
        onclick: "window.Dummy.Ui.Flash.flash({ content: 'New danger message!', variant: 'danger' })" },
      { variant: :info, loader: true, label: "Add loader flash",
        onclick: "window.Dummy.Ui.Flash.flash({ content: 'New loader message!', variant: 'loader' })" },
    ]
  end

  def pagination
    @pagy, _records = pagy(Dummy::Blog::Article, items: 1)
  end

  def images
    @image = (Folio::File::Image.tagged_with("unsplash").presence || Folio::File::Image).first

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

  def chips
    links = Array.new(16) do |i|
      label = Faker::Hipster.word.capitalize

      { label:, href: "##{label.parameterize}", current: i == 1 }
    end

    @chips = [
      { links:, small: true },
      { links: },
      { links:, large: true },
    ]
  end

  def topics
    topics = Array.new(16) do |i|
      label = if [3, 4].include?(i)
        Faker::Hipster.sentence.delete_suffix(".")
      else
        Faker::Hipster.word.capitalize
      end

      { label:, href: "##{label.parameterize}", active: i == 1 }
    end

    @topics = {
      "Default" => { topics: },
      "Centered" => { topics:, centered: true },
      "Small" => { topics:, small: true },
      "Small centered" => { topics:, centered: true, small: true },
    }
  end

  def hero
    # TODO: tag images with dark/light theme
    images = Folio::File::Image.tagged_with("unsplash").presence || Folio::File::Image

    cover = images.first
    background_cover = images.second

    @hero_variants = [
      {
        cover:,
        title: "One and two gallery title",
        perex: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed ultricies nulla nisl, nec semper enim varius a. Integer tortor sapien, congue a suscipit quis",
        show_divider: true,
      },
      {
        cover:,
        title: "One and two gallery title",
        perex: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed ultricies nulla nisl, nec semper enim varius a. Integer tortor sapien, congue a suscipit quis",
        date: Time.current.to_date,
        authors: [{ name: "John Doe", href: request.path, cover: }],
        show_divider: true,
      }, {
        cover:,
        title: "One and two gallery title",
        perex: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed ultricies nulla nisl, nec semper enim varius a. Integer tortor sapien, congue a suscipit quis",
        image_size: "extra_large",
        show_divider: true,
      }, {
        cover:,
        title: "One and two gallery title",
        perex: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed ultricies nulla nisl, nec semper enim varius a. Integer tortor sapien, congue a suscipit quis",
        image_size: "large",
        show_divider: true,
      }, {
        cover:,
        title: "One and two gallery title",
        perex: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed ultricies nulla nisl, nec semper enim varius a. Integer tortor sapien, congue a suscipit quis",
        image_size: "medium",
        show_divider: true,
      }, {
        cover:,
        title: "One and two gallery title",
        perex: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed ultricies nulla nisl, nec semper enim varius a. Integer tortor sapien, congue a suscipit quis",
        image_size: "small",
      }, {
        cover:,
        title: "One and two gallery title",
        perex: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed ultricies nulla nisl, nec semper enim varius a. Integer tortor sapien, congue a suscipit quis",
        image_size: "full_width",
      }, {
        cover:,
        background_color: "#D4E6C9",
        title: "One and two gallery title",
        perex: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed ultricies nulla nisl, nec semper enim varius a. Integer tortor sapien, congue a suscipit quis",
        show_divider: true,
      }, {
        cover:,
        background_color: "#D4E6C9",
        title: "One and two gallery title",
        perex: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed ultricies nulla nisl, nec semper enim varius a. Integer tortor sapien, congue a suscipit quis",
        image_size: "medium",
        show_divider: true,
      }, {
        title: "One and two gallery title",
        perex: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed ultricies nulla nisl, nec semper enim varius a. Integer tortor sapien, congue a suscipit quis",
        background_color: "#D4E6C9",
      }, {
        background_cover:,
        title: "One and two gallery title",
        perex: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed ultricies nulla nisl, nec semper enim varius a. Integer tortor sapien, congue a suscipit quis",
      }, {
        cover:,
        background_cover:,
        title: "One and two gallery title",
        perex: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed ultricies nulla nisl, nec semper enim varius a. Integer tortor sapien, congue a suscipit quis",
        image_size: "small",
      }, {
        background_cover:,
        title: "One and two gallery title",
        perex: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed ultricies nulla nisl, nec semper enim varius a. Integer tortor sapien, congue a suscipit quis",
        background_overlay: "light",
      }, {
        background_cover:,
        title: "One and two gallery title",
        perex: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed ultricies nulla nisl, nec semper enim varius a. Integer tortor sapien, congue a suscipit quis",
        background_overlay: "dark",
        theme: "dark",
      }, {
        background_cover:,
        title: "One and two gallery title",
        perex: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed ultricies nulla nisl, nec semper enim varius a. Integer tortor sapien, congue a suscipit quis",
        background_overlay: "dark",
        theme: "dark",
        authors: [
          { name: "John Doe", href: "#", cover: Folio::File::Image.tagged_with("unsplash").first },
        ],
      }, {
        title: "One and two gallery title",
        perex: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed ultricies nulla nisl, nec semper enim varius a. Integer tortor sapien, congue a suscipit quis",
      }
    ]
  end

  def slide_lists; end

  def tabs
    @tabs = [
      {
        href: tabs_dummy_ui_path(tab: "1"),
        active: %w[2 3].exclude?(params[:tab]),
        label: "Tab 1",
      },
      {
        href: tabs_dummy_ui_path(tab: "2"),
        active: params[:tab] == "2",
        label: "Tab 2",
        count: 123,
      },
      {
        href: tabs_dummy_ui_path(tab: "3"),
        active: params[:tab] == "3",
        label: "Tab 3",
        disabled: true,
        count: 2,
      },
    ]
  end

  def documents
    @document_placements = Folio::File::Document.last(5).map do |doc|
      Folio::FilePlacement::Document.new(file: doc)
    end
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
