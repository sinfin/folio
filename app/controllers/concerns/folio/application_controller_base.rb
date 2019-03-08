# frozen_string_literal: true

module Folio::ApplicationControllerBase
  extend ActiveSupport::Concern

  included do
    include Pagy::Backend

    protect_from_forgery with: :exception

    layout 'folio/application'

    helper_method :current_admin

    before_action do
      @site = Folio::Site.instance
      I18n.locale = params[:locale] || @site.locale
    end
  end

  def current_admin
    current_account
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

  private

    def nested_page_path(page)
      return nil unless main_app.respond_to?(:page_path)

      parts = [page]

      while page = page.parent
        parts << page
      end

      path = parts.reverse.map(&:slug).join('/')
      main_app.page_path(path: path)
    end

    def set_meta_variables(instance, mappings = {})
      m = {
        title: :title,
        image: :cover,
        description: :perex,
        meta_title: :meta_title,
        meta_description: :meta_description,
      }.merge(mappings)

      if image = instance.try(m[:image]).presence
        @og_image = image.thumb(Folio::OG_IMAGE_DIMENSIONS).url
      end

      title = instance.try(m[:title]).presence
      og_title = instance.try(m[:meta_title]).presence
      @public_page_title = og_title || title

      description = instance.try(m[:description]).presence
      og_description = instance.try(m[:meta_description]).presence
      @public_page_description = og_description || description
    end

    def force_correct_path(correct_path_or_url)
      # If an old id or a numeric id was used to find the record, then
      # the request path will not match the post_path, and we should do
      # a 301 redirect that uses the current friendly id.
      if request.path != correct_path_or_url &&
         request.url != correct_path_or_url
        redirect_to(correct_path_or_url, status: :moved_permanently)
      end
    end
end
