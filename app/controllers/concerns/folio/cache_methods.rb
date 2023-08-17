# frozen_string_literal: true

module Folio::CacheMethods
  extend ActiveSupport::Concern

  included do
    helper_method :render_folio_cache
  end

  private
    def folio_run_unless_cached(key, meta: true, &block)
      @folio_cache_key = key

      if ::Rails.application.config.action_controller.perform_caching && !params[:skip_global_cache]
        @folio_cached_html = Rails.cache.read(@folio_cache_key)

        if meta
          @folio_meta_variables_cache_key = ["meta"] + @folio_cache_key
          @folio_cached_meta_html = Rails.cache.read(@folio_meta_variables_cache_key)
        end
      end

      if !::Rails.application.config.action_controller.perform_caching ||
         params[:skip_global_cache] ||
         !@folio_cached_html ||
         !@folio_cached_meta_html
        yield block
      end
    end

    def render_folio_cache(&block)
      if params[:skip_global_cache] || !::Rails.application.config.action_controller.perform_caching
        yield block
      elsif @folio_cached_html
        @folio_cached_html
      else
        Rails.cache.fetch(@folio_cache_key, &block)
        nil
      end
    end
end
