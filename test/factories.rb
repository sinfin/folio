# frozen_string_literal: true

FactoryBot.define do
  factory :folio_site, class: 'Folio::Site' do
    title { 'Folio' }
    sequence(:domain) { |n| "folio-#{n}.com" }
    email { 'folio@folio.folio' }
    social_links { { 'facebook' => 'http://www.facebook.com/folio' } }
    address { "90682 Folio Square\nFolio" }
    phone { '+420 123456789' }
    locale { :cs }
    locales { [:cs] }
  end

  factory :folio_page, class: 'Folio::Page' do
    locale { :cs }
    if Rails.application.config.folio_using_traco
      I18n.available_locales.each do |locale|
        sequence("title_#{locale}".to_sym) { |n| "Folio node #{n}" }
        sequence("slug_#{locale}".to_sym) { |n| "folio-node-#{n}" }
      end
    else
      sequence(:title) { |n| "Folio node #{n}" }
      sequence(:slug) { |n| "folio-node-#{n}" }
    end
    published { true }
    published_at { 1.day.ago }

    trait :unpublished do
      published { false }
      published_at { nil }
    end
  end

  factory :folio_page_cookies, parent: :folio_page, class: 'Folio::Page::Cookies'

  factory :folio_atom, class: 'Folio::Atom::Text' do
    type { 'Folio::Atom::Text' }
    association :placement, factory: :folio_node
    content { '<p>Officiis perferendis commodi. Asperiores quas et. Veniam qui est.</p>' }
  end

  factory :folio_document_placement, class: 'Folio::FilePlacement::Document' do
    association :file, factory: :folio_document
    association :placement, factory: :folio_page
  end

  factory :folio_image_placement, class: 'Folio::FilePlacement::Image' do
    association :file, factory: :folio_image
    association :placement, factory: :folio_page
  end

  factory :folio_cover_placement, class: 'Folio::FilePlacement::Cover' do
    association :file, factory: :folio_image
    association :placement, factory: :folio_page
  end

  factory :folio_image, class: 'Folio::Image' do
    file { Folio::Engine.root.join('test/fixtures/folio/test.gif') }

    trait :black do
      file { Folio::Engine.root.join('test/fixtures/folio/test-black.gif') }
    end
  end

  factory :folio_document, class: 'Folio::Document' do
    file { Folio::Engine.root.join('test/fixtures/folio/empty.pdf') }
  end

  factory :folio_lead, class: 'Folio::Lead' do
    email { 'folio@folio.folio' }
    phone { '+420 123456789' }
    note { 'Officiis perferendis commodi.' }
  end

  factory :folio_admin_account, class: 'Folio::Account' do
    email { 'test@test.com' }
    password { '123456' }
    role { :superuser }
    first_name { 'Test' }
    last_name { 'Dummy' }
  end

  factory :folio_menu, class: 'Folio::Menu::Page' do
    locale { :cs }

    factory :folio_menu_with_menu_items do
      transient do
        items_count { 3 }
      end

      after(:create) do |menu, evaluator|
        create_list(:folio_menu_item, evaluator.items_count, menu: menu)
      end
    end
  end

  factory :folio_menu_item, class: 'Folio::MenuItem' do
    association :menu, factory: :folio_menu
    association :target, factory: :folio_node
    title { 'MenuItem' }
    position { 0 }
  end
end
