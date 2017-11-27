# frozen_string_literal: true

FactoryGirl.define do
  factory :admin_account, class: Folio::Account do
    email 'test@test.com'
    password '123456'
    role :superuser
    first_name 'Test'
    last_name 'Dummy'
  end
end
