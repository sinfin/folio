# frozen_string_literal: true

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'factory_girl'
require_relative '../config/initializers/folio'

FactoryGirl.definition_file_paths << File.join(File.dirname(__FILE__), 'factories')
FactoryGirl.find_definitions

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
  include ::FactoryGirl::Syntax::Methods
end

class Cell::TestCase
  controller ApplicationController
  include ::FactoryGirl::Syntax::Methods
end
