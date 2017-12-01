# frozen_string_literal: true

require 'faker'
I18n.reload!

FactoryGirl.define do
  factory :folio_site, class: Folio::Site do
    title { Faker::Lorem.word }
    domain { Faker::Internet.domain_name }
    social_links { { 'facebook' => Faker::Internet.url('facebook.com') } }
    address { [Faker::Address.street_address, Faker::Address.city].join("\n") }
  end

  factory :folio_node, class: Folio::Node do
    locale :cs
    title { Faker::Lorem.word }
    association :site, factory: :folio_site

    factory :folio_node_with_atoms do
      transient do
        atoms_count 3
      end
      after(:create) do |node, evaluator|
        node.atoms = create_list(:folio_atom, evaluator.atoms_count)
      end
    end
  end

  factory :folio_atom, class: Folio::Atom do
    content { Faker::Lorem.paragraph }
    association :node, factory: :folio_node
  end

  factory :folio_image, class: Folio::Image do
    file Folio::Engine.root.join('test/fixtures/folio/test.gif')
  end

  factory :folio_lead, class: Folio::Lead do
    email { Faker::Internet.email }
    phone { Faker::PhoneNumber.phone_number }
    note { Faker::Lorem.paragraph }
  end
end
