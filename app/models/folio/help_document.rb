# frozen_string_literal: true

module Folio
  class HelpDocument
    include ActiveModel::Model

    attr_accessor :slug, :title, :description, :order, :category, :path, :content, :updated_at

    class << self
      def all
        return [] unless config_exists?

        documents = []
        config_data["documents"].each_with_index do |doc_data, index|
          if doc_data["slug"].present?
            documents << new(
              slug: doc_data["slug"],
              title: doc_data["title"],
              description: doc_data["description"],
              order: doc_data["order"] || index,
              category: doc_data["category"],
              path: File.join(help_directory, "#{doc_data["slug"]}.md")
            )
          end
        end
        documents.sort_by(&:order)
      end

      def find(slug)
        all.find { |doc| doc.slug == slug }
      end

      def config_exists?
        File.exist?(config_path)
      end

      def help_directory
        Rails.root.join("doc", "help")
      end

      def config_path
        help_directory.join("index.yml")
      end

      def config_data
        return {} unless config_exists?
        @config_data ||= YAML.load_file(config_path)
      rescue StandardError => e
        Rails.logger.error "Error loading help config: #{e.message}"
        {}
      end

      def reload!
        @config_data = nil
      end
    end

    def content
      @content ||= if File.exist?(path)
        File.read(path)
      else
        ""
      end
    end

    def updated_at
      @updated_at ||= begin
        if File.exist?(path)
          # Try to get last commit date from git
          result = `git log -1 --format="%aI" -- "#{path}" 2>/dev/null`.strip
          if result.present?
            Time.parse(result)
          else
            File.mtime(path)
          end
        else
          Time.current
        end
      rescue StandardError
        File.exist?(path) ? File.mtime(path) : Time.current
      end
    end

    def exists?
      File.exist?(path)
    end
  end
end 