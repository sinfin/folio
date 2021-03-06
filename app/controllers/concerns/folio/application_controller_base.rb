# frozen_string_literal: true

module Folio::ApplicationControllerBase
  extend ActiveSupport::Concern
  include Folio::SetMetaVariables
  include Folio::HasCurrentSite

  included do
    include Pagy::Backend

    protect_from_forgery with: :exception

    layout "folio/application"

    before_action :set_i18n_locale

    helper_method :current_site
  end

  def set_i18n_locale
    I18n.locale = params[:locale] || current_site.locale
  end

  def default_url_options
    { only_path: true }
  end

  def url_for(options = nil)
    if Rails.application.config.folio_pages_ancestry &&
       options &&
       options.is_a?(Folio::Page)
      nested_page_path(options)
    else
      super(options)
    end
  end

  def current_site
    @current_site ||= Folio::Site.instance
  end

  private
    def nested_page_path(page)
      return nil unless main_app.respond_to?(:page_path)
      main_app.page_path(path: page.nested_page_path)
    end

    def force_correct_path(correct_path_or_url)
      # If an old id or a numeric id was used to find the record, then
      # the request path will not match the post_path, and we should do
      # a 301 redirect that uses the current friendly id.
      if request.path != correct_path_or_url &&
         request.url != correct_path_or_url
        redirect_to(correct_path_or_url, status: :moved_permanently)
        true
      else
        false
      end
    end

    def atom_includes
      [
        atoms: {
          cover_placement: :file,
          document_placement: :file,
          image_placements: :file,
          document_placements: :file,
        }
      ]
    end
end
