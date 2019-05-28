# frozen_string_literal: true

if defined?(Premailer)
  Premailer::Rails.config[:drop_unmergeable_css_rules] = true
end
