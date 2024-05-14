# frozen_string_literal: true

require "rubygems"
require "sitemap_generator"
require "aws-sdk-s3"

module Folio::SitemapGenerator
  module Helper
    def includes_image_sitemap_scope(scope)
      scope = scope.all

      if scope.klass.method_defined?(:atoms)
        if locales = scope.klass.try(:atom_locales)
          locales.each do |locale|
            scope = scope.includes("#{locale}_atoms": [ cover_placement: :file,
                                                        image_placements: :file ])
          end
        else
          scope = scope.includes(atoms: [ cover_placement: :file,
                                          image_placements: :file ])
        end
      end

      if scope.klass.method_defined?(:file_placements)
        scope = scope.includes(cover_placement: :file, image_placements: :file)
      end

      scope
    end
  end
end
SitemapGenerator::Interpreter.send :include, Folio::SitemapGenerator::Helper

unless Rails.env.development?
  SitemapGenerator::Sitemap.public_path = "tmp/"
  SitemapGenerator::Sitemap.adapter = SitemapGenerator::AwsSdkAdapter.new(
    ENV["S3_BUCKET_NAME"],
    aws_access_key_id: ENV["AWS_ACCESS_KEY_ID"],
    aws_secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
    aws_region: ENV["S3_REGION"],
    aws_session_token: ENV.fetch("AWS_SESSION_TOKEN", nil)
  )
end

# override urls in sitemap index file because of the way SitemapController is set up
SitemapGenerator::Builder::SitemapIndexUrl.class_eval do
  alias_method :original_initialize, :initialize
  def initialize(path, options = {})
    path.location[:sitemaps_path] = "sitemaps" unless path.is_a?(SitemapGenerator::Builder::SitemapIndexFile)
    original_initialize(path, options)
  end
end
