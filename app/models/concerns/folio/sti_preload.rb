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

      def preload_sti
        return if sti_paths.blank? && sti_file_paths.blank?

        preload_path = -> (path) do
          relative_path = path.sub(/.*\/app\/models\//, "").delete_suffix(".rb")
          classified = "#{relative_path}/X".classify.delete_suffix("::X")
          if classified.safe_constantize
            logger.debug("Preloading STI type #{classified}")
          else
            logger.error("Failed to preload STI file: #{path}")
          end
        end

        sti_paths.each do |sti_path|
          Dir["#{sti_path}/**/*.rb"].each do |path|
            preload_path.call(path)
          end
        end

        sti_file_paths.each do |sti_file_path|
          preload_path.call(sti_file_path)
        end

        self.sti_preloaded = true
      end
    end
  end
end
