# frozen_string_literal: true

module Folio
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception

    before_action do
      @site = Folio::Site.first
      @roots = Folio::Node.roots
    end
  end
end
