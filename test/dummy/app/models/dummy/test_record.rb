# frozen_string_literal: true

class Dummy::TestRecord < ApplicationRecord
  # extend and use in tests to test folio concerns

  self.table_name = "dummy_test_records"
end
