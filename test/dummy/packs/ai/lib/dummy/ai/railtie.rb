# frozen_string_literal: true

module Dummy
  module Ai
    class Railtie < ::Rails::Railtie
      config.to_prepare do
        unless Dummy::Blog::Article < Dummy::Ai::BlogArticleConcern
          Dummy::Blog::Article.include(Dummy::Ai::BlogArticleConcern)
        end
      end
    end
  end
end
