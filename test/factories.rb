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

  factory :atom, class: Folio::Atom do
    content { Faker::Lorem.paragraph }
    node
  end

  factory :image, class: Folio::Image do
    file Folio::Engine.root.join('test/fixtures/folio/test.gif')
  end

  factory :lead, class: Folio::Lead do
    email { Faker::Internet.email }
    phone { Faker::PhoneNumber.phone_number }
    note { Faker::Lorem.paragraph }
  end
end
