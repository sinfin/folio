# frozen_string_literal: true

FactoryGirl.define do
  factory :folio_menu, class: Folio::Menu::Header do
    factory :folio_menu_with_menu_items do
      transient do
        posts_count 3
      end

      after(:create) do |menu, evaluator|
        create_list(:folio_menu_item, evaluator.posts_count, menu: menu)
      end
    end
  end

  factory :folio_menu_item, class: Folio::MenuItem do
    association :node, factory: :folio_node
    title { Faker::Lorem.word }
    position 0
  end
end
