# frozen_string_literal: true

Devise::SessionsController.class_eval do
  before_action :set_anti_cache_purge_flag, only: [:create, :destroy]

  private
    def set_anti_cache_purge_flag
      session[:folio_anti_cache_purge] = true
    end
end
