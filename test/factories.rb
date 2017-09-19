# frozen_string_literal: true

require 'faker'
I18n.reload!

FactoryGirl.define do
  factory :site, class: Folio::Site do
    title { Faker::Lorem.word }
    domain { Faker::Internet.domain_name }
  end

  factory :node, class: Folio::Node do
    title { Faker::Lorem.word }
    site
  end
end
