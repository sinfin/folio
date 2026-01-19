# frozen_string_literal: true

# Extend packwerk to include Folio engine paths in load_paths
# This is needed because packwerk filters out paths outside Rails.root

if defined?(Packwerk)
  module Packwerk
    module RailsLoadPathsExtension
      def filter_relevant_paths(all_paths, bundle_path: Bundler.bundle_path, rails_root: Rails.root)
        # Get the original filtered paths
        result = super

        # Also include Folio engine paths (parent of test/dummy)
        engine_root = rails_root.join("../..")
        engine_root_match = engine_root.join("**")

        engine_paths = all_paths
          .transform_keys { |path| Pathname.new(path).expand_path }
          .select { |path| path.fnmatch(engine_root_match.to_s) }
          .reject { |path| path.fnmatch(bundle_path.join("**").to_s) }
          .reject { |path| path.to_s.include?("/test/dummy/") } # avoid duplicates

        result.merge(engine_paths)
      end
    end

    RailsLoadPaths.singleton_class.prepend(RailsLoadPathsExtension)
  end
end
