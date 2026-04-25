# frozen_string_literal: true

# Packwerk normally filters load paths to Rails.root. Folio runs Packwerk from
# test/dummy, so the engine root and enabled packs must be put back into the
# relevant path set for static dependency checks.
if defined?(Packwerk)
  module Packwerk
    module RailsLoadPathsExtension
      def filter_relevant_paths(all_paths, bundle_path: Bundler.bundle_path, rails_root: Rails.root)
        result = super
        engine_root = rails_root.join("../..")
        engine_root_match = engine_root.join("**").to_s

        engine_paths = all_paths
                       .transform_keys { |path| Pathname.new(path).expand_path }
                       .select { |path| path.fnmatch(engine_root_match) }
                       .reject { |path| path.fnmatch(bundle_path.join("**").to_s) }
                       .reject { |path| path.to_s.include?("/test/dummy/") }

        result.merge(engine_paths)
      end
    end

    RailsLoadPaths.singleton_class.prepend(RailsLoadPathsExtension)
  end
end
