# frozen_string_literal: true

module Folio
  class HelpDocument
    include ActiveModel::Model

    attr_accessor :slug, :title, :description, :order, :category, :path

    class << self
      def all
        return [] unless config_exists?

        documents = []
        return [] unless config_data["documents"]

        config_data["documents"].each_with_index do |doc_data, index|
          if doc_data["slug"].present?
            documents << new(
              slug: doc_data["slug"],
              title: doc_data["title"],
              description: doc_data["description"],
              order: doc_data["order"] || index,
              category: doc_data["category"],
              path: doc_data["path"] || ::File.join(help_directory, "#{doc_data["slug"]}.md")
            )
          end
        end
        documents.sort_by(&:order)
      end

      def find(slug)
        all.find { |doc| doc.slug == slug }
      end

      def config_exists?
        ::File.exist?(config_path)
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
      @content ||= if ::File.exist?(path)
        ::File.read(path)
      else
        ""
      end
    end

    def updated_at
      @updated_at ||= begin
        if ::File.exist?(path)
          git_date = git_last_modified_date
          git_date || ::File.mtime(path)
        else
          Time.current
        end
      rescue StandardError
        ::File.exist?(path) ? ::File.mtime(path) : Time.current
      end
    end

    def exists?
      ::File.exist?(path)
    end

    private
      def git_last_modified_date
        return nil unless git_available? && in_git_repository? && file_tracked_by_git?

        result = `git log -1 --format="%aI" -- "#{path}" 2>/dev/null`.strip
        return nil if result.blank?

        Time.parse(result)
      rescue StandardError
        nil
      end

      def git_available?
        system("which git > /dev/null 2>&1")
      end

      def in_git_repository?
        system("git rev-parse --git-dir > /dev/null 2>&1")
      end

      def file_tracked_by_git?
        return false unless ::File.exist?(path)

        # Check if file is tracked by git
        system("git ls-files --error-unmatch '#{path}' > /dev/null 2>&1")
      end
  end
end
