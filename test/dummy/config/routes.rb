# frozen_string_literal: true

Rails.application.routes.draw do

  mount Folio::Engine => '/'
end
