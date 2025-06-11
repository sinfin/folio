# frozen_string_literal: true

require Folio::Engine.root.join("app/models/concerns/folio/html_sanitization/model")

ActsAsTaggableOn::Tag.class_eval do
  include Folio::HtmlSanitization::Model
end
