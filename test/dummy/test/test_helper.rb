# frozen_string_literal: true

require File.expand_path("../../config/environment", __FILE__)
require Folio::Engine.root.join("test/test_helper_base")

FactoryBot.definition_file_paths << File.join(File.dirname(__FILE__), "factories")
FactoryBot.find_definitions
