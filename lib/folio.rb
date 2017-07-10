# frozen_string_literal: true

require 'folio/engine'
require 'friendly_id'
require 'ancestry'
require 'devise'
require 'slim'
require 'sass-rails'
require 'bootstrap-sass'

module Folio
  class Engine < ::Rails::Engine
    config.assets.precompile += %w[folio/console/base.css folio/console/base.js]
  end
end
