# frozen_string_literal: true

module Folio::StiPreload
  unless Rails.application.config.eager_load
    extend ActiveSupport::Concern

    included do
      cattr_accessor :sti_preloaded, instance_accessor: false
    end

    class_methods do
      def sti_paths
        []
      end

      def sti_file_paths
        []
      end

      def descendants
        preload_sti unless sti_preloaded
        super
      end

      # Handles nested STI hierarchies with intermediate base classes.
      # Retries failed loads until all dependencies are resolved or no progress is made.
      # This is more robust than relying on file ordering or naming conventions.
      def preload_sti
        files_to_load = []

        sti_paths.each do |sti_path|
          files_to_load.concat(Dir["#{sti_path}/**/*.rb"])
        end

        sti_file_paths.each do |path|
          files_to_load << path.to_s
        end

        remaining = files_to_load
        loop do
          failed = []

          remaining.each do |path|
            relative_path = path.sub(/.*\/app\/models\//, "").delete_suffix(".rb")
            classified = "#{relative_path}/X".classify.delete_suffix("::X")

            begin
              classified.constantize
              logger.debug("Preloading STI type #{classified}")
            rescue NameError
              # Dependency not yet loaded, retry later
              failed << path
            end
          end

          # Stop if all loaded or no progress made (prevents infinite loop)
          break if failed.empty? || failed.size == remaining.size

          remaining = failed
        end

        # Log any files that couldn't be loaded after all retries
        remaining.each do |path|
          relative_path = path.sub(/.*\/app\/models\//, "").delete_suffix(".rb")
          classified = "#{relative_path}/X".classify.delete_suffix("::X")
          logger.error("Failed to preload STI file: #{path} (#{classified})")
        end

        self.sti_preloaded = true
      end
    end
  end
end
