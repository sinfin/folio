# frozen_string_literal: true

class Folio::UiCell < Folio::ApplicationCell
  include SimpleForm::ActionViewExtensions::FormHelper
  include ActionView::Helpers::FormOptionsHelper
  include Pagy::Backend

  def show
    if model.present?
      @mobile_only = true
      render(:_typo)
    else
      render
    end
  end

  def sites
    @sites ||= Folio::Site.ordered.to_a
  end

  def sites_tabs_model
    @sites.map do |site|
      {
        href: controller.folio.folio_ui_url(host: site.env_aware_domain, only_path: false),
        active: site == current_site,
        label: site.to_label
      }
    end
  end

  def typo_titles
    %w[h1 h2 h3 h4 h5]
  end

  def main_colors
    %w[blue primary]
  end

  def additional_colors
    %w[light-gray medium-gray gray dark-gray blue red purple green orange yellow]
  end

  def button_variants
    %w[primary secondary]
  end

  def typo_paragraphs
    ["lead", nil, "small"]
  end

  def button_sizes
    [nil, "btn-sm", "btn-lg"]
  end

  def application_namespace
    @application_namespace ||= ::Rails.application.class.name.deconstantize
  end

  def application_namespace_path
    @application_namespace_path ||= application_namespace.underscore
  end

  def pagy_model
    pagy, _pages = pagy(Folio::Page.all, items: 1)
    pagy
  end

  def tabs_model
    [
      { href: "#", active: true, label: "Current tab" },
      { href: "#", label: "Another tab" },
      { href: "#", label: "Another tab" },
    ]
  end

  def missing_cell(cell_key)
    content_tag(:p,
                "No #{cell_key} cell. Run <code>rails g folio:ui #{cell_key}</code> to create one.",
                class: "text-danger")
  end

  def icons
    "#{application_namespace}::Ui::IconCell".constantize::ICONS.keys
  rescue StandardError
  end

  def flash_models
    %i[notice success warning alert].map do |key|
      flash_hash = ActionDispatch::Flash::FlashHash.new
      flash_hash[key] = key
      flash_hash
    end
  end

  def navigation_model
    Folio::Menu.order(updated_at: :desc).first
  end

  def documents_model
    documents = Folio::Document.last(3)

    documents.map do |doc|
      Folio::FilePlacement::Document.new(file: doc)
    end
  end

  def image
    @image ||= Folio::Image.tagged_with("unsplash").first
  end

  def card_model
    @card_model ||= {
      title: "This is a section title",
      content: "<p>Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p>",
      button_label: "Button label",
      href: "/folio/ui",
      cover_placement: image ? Folio::FilePlacement::Cover.new(file: image) : nil,
    }
  end

  def card_variants(opts = {})
    [
      %i[cover_placement content title],
      %i[cover_placement content],
      %i[cover_placement title],
      %i[cover_placement],
      %i[content title],
      %i[content],
      %i[title],
      %i[],
    ].map do |keys|
      card_model.slice(*keys, :href, :button_label).merge(opts)
    end
  end
end
