# frozen_string_literal: true

module Folio::ApplicationControllerBase
  extend ActiveSupport::Concern

  included do
    include Pagy::Backend

    protect_from_forgery with: :exception

    layout 'folio/application'

    helper_method :current_admin
    helper_method :nested_page_path
    helper_method :page_roots

    before_action do
      @site = Folio::Site.instance
      I18n.locale = params[:locale] || @site.locale
    end
  end

  def current_admin
    current_account
  end

  def nested_page_path(page_or_parts, add_parents: true, params: {})
    return nil unless main_app.respond_to?(:page_path)

    if add_parents
      nested_page_path_with_parents(page_or_parts, params: params)
    else
      if page_or_parts.respond_to?(:slug)
        path = page_or_parts.slug
      elsif page_or_parts.is_a?(Array)
        path = page_or_parts.map(&:slug).join('/')
      else
        fail 'Unknown nested_page_path target'
      end

      main_app.page_path(params.merge(path: path))
    end
  end

  private

    def nested_page_path_with_parents(page, params: {})
      path = [page]
      while page.parent
        # TODO: translate?
        path.unshift page.parent
        page = page.parent
      end
      main_app.page_path(params.merge(path: path.map(&:slug).join('/')))
    end

    def page_roots
      @page_roots ||= begin
        if ::Rails.application.config.folio_using_traco
          Folio::Page.roots.ordered
        else
          Folio::Page.by_locale(I18n.locale).roots.ordered
        end
      end
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

    def force_correct_path(correct_path)
      # If an old id or a numeric id was used to find the record, then
      # the request path will not match the post_path, and we should do
      # a 301 redirect that uses the current friendly id.
      if request.path != correct_path
        redirect_to(correct_path, status: :moved_permanently)
      end
    end
end
