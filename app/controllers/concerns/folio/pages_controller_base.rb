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

        @page = pages_scope.published_or_admin(current_account.present?)
                           .friendly
                           .find(path.shift)
        add_breadcrumb @page.title, page_path(@page)

        path.each do |slug|
          children = filter_pages_by_locale(@page.children)
          @page = children.published_or_admin(current_account.present?)
                          .friendly
                          .find(slug)
          add_breadcrumb @page.title, nested_page_path(@page)
        end

        force_correct_path(nested_page_path(@page))
      else
        @page = pages_scope.published_or_admin(current_account.present?)
                           .friendly
                           .find(params[:id])
        add_breadcrumb @page.title, url_for(@page)
        force_correct_path(url_for(@page))
      end
    end

    def add_meta
      set_meta_variables(@page)
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
