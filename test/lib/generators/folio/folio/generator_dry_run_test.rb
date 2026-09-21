# frozen_string_literal: true

require "test_helper"
require "generators/folio/atom/atom_generator"
require "generators/folio/tiptap/node/node_generator"
require "generators/folio/ui/ui_generator"

module Folio
  module GeneratorDryRunTestHelper
    private
      def assert_locale_files_unchanged(paths)
        initial_contents = paths.index_with { |path| ::File.binread(path) }

        yield

        paths.each do |path|
          assert_equal initial_contents.fetch(path), ::File.binread(path), path.to_s
        end
      ensure
        initial_contents&.each do |path, content|
          next if ::File.binread(path) == content

          ::File.binwrite(path, content)
        end
      end
  end

  class AtomGeneratorDryRunTest < Rails::Generators::TestCase
    include GeneratorDryRunTestHelper

    tests Folio::AtomGenerator
    destination Rails.root.join("tmp/generators/atom_dry_run")
    setup :prepare_destination

    test "does not update atom locales when pretending" do
      paths = %i[cs en].map { |locale| Rails.root.join("config/locales/atom.#{locale}.yml") }

      assert_locale_files_unchanged(paths) do
        run_generator ["generator_dry_run_fixture", "--pretend"]
      end
    end
  end

  class TiptapNodeGeneratorDryRunTest < Rails::Generators::TestCase
    include GeneratorDryRunTestHelper

    tests Folio::Tiptap::NodeGenerator
    destination Rails.root.join("tmp/generators/tiptap_node_dry_run")
    setup :prepare_destination

    test "does not update node locales when pretending" do
      paths = %i[cs en].map { |locale| Rails.root.join("config/locales/tiptap/nodes.#{locale}.yml") }

      assert_locale_files_unchanged(paths) do
        run_generator ["generator_dry_run_fixture", "--pretend"]
      end
    end
  end

  class UiGeneratorDryRunTest < Rails::Generators::TestCase
    include GeneratorDryRunTestHelper

    tests Folio::UiGenerator
    destination Rails.root.join("tmp/generators/ui_dry_run")
    setup :prepare_destination

    test "does not update UI locales when pretending" do
      paths = %i[cs en].map { |locale| Rails.root.join("config/locales/ui.#{locale}.yml") }

      assert_locale_files_unchanged(paths) do
        run_generator ["alert", "--pretend"]
      end
    end
  end
end
