# frozen_string_literal: true

module Folio::PagesControllerBase
  extend ActiveSupport::Concern

  included do
    include Folio::UrlHelper

    before_action :find_page, :add_meta
  end

  def show
    if @page.class.view_name
      render @page.class.view_name
    else
      render 'folio/pages/show'
    end
  end

  private

    def find_page
      if Rails.application.config.folio_pages_ancestry
        path = params[:path].split('/')

        @page = pages_scope.published_or_admin(admin_preview?)
                           .friendly
                           .find(path.shift)
        add_breadcrumb @page.title, nested_page_path(@page, add_parents: true)

        path.each do |path_part|
          children = filter_pages_by_locale(@page.children)
          @page = children.published_or_admin(admin_preview?)
                          .friendly
                          .find(path_part)
          add_breadcrumb @page.title, nested_page_path(@page, add_parents: true)
        end

        force_correct_path(nested_page_path(@page, add_parents: true))
      else
        @page = pages_scope.published_or_admin(admin_preview?)
                           .friendly
                           .find(params[:id])
        add_breadcrumb @page.title, url_for(@page)
        force_correct_path(url_for(@page))
      end
    end

    def add_meta
      set_meta_variables(@page)
    end

    def admin_preview?
      current_admin.present?
    end

    def filter_pages_by_locale(pages)
      if Rails.application.config.folio_pages_translations
        pages.by_locale(I18n.locale)
      else
        pages
      end
    end

    def pages_scope
      base = Folio::Page
      base = base.roots if Rails.application.config.folio_pages_ancestry
      filter_pages_by_locale(base)
    end
end
