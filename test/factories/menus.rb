# frozen_string_literal: true

FactoryGirl.define do
  factory :menu, class: Folio::Menu::Header do
    factory :menu_with_menu_items do
      transient do
        posts_count 3
      end

      after(:create) do |menu, evaluator|
        create_list(:menu_item, evaluator.posts_count, menu: menu)
      end
    end
  end
end

FactoryGirl.define do
  factory :menu_item, class: Folio::MenuItem do
    node
    title { Faker::Lorem.word }
    position 0
  end
end
