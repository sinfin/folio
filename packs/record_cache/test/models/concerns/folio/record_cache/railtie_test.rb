# frozen_string_literal: true

require "test_helper"

module Folio
  module RecordCache
    class RailtieTest < ActiveSupport::TestCase
      test "Folio models include Identity Cache when pack is enabled" do
        assert Folio::Site.include?(::IdentityCache)
        assert Folio::File.include?(::IdentityCache)
        assert Folio::Menu.include?(::IdentityCache)
      end

      test "Page includes Identity Cache only when not using Traco" do
        if Rails.application.config.folio_using_traco
          assert_not Folio::Page.include?(::IdentityCache)
        else
          assert Folio::Page.include?(::IdentityCache)
        end
      end
    end
  end
end
