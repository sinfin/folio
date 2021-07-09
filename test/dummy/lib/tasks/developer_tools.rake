# frozen_string_literal: true

namespace :developer_tools do
  task idp_seed_singleton_pages: :environment do
    Rails.logger.silence do
      Dir.glob(Rails.root.join("data/seed/pages/*.yml")).each do |yaml_path|
        data = YAML.load_file(yaml_path)
        klass = data["type"].constantize

        if !klass.exists? || ENV["FORCE"] || ENV["FORCE_SINGLETON"] == klass.to_s
          klass.find_each { |o| o.try(:force_destroy=, true); o.destroy! }

          klass.create!(title: data["title"],
                        perex: data["perex"],
                        published: true,
                        published_at: 1.minute.ago)

          puts "Created #{klass}"
        else
          puts "Skipping existing #{klass}"
        end
      end
    end
  end

  task idp_seed_singleton_menus: :environment do
    Rails.logger.silence do
      Dir.glob(Rails.root.join("data/seed/menus/*.yml")).each do |yaml_path|
        data = YAML.load_file(yaml_path)
        klass = data["type"].constantize

        if !klass.exists? || ENV["FORCE"] || ENV["FORCE_SINGLETON"] == klass.to_s
          klass.find_each { |o| o.try(:force_destroy=, true); o.destroy! }

          menu = klass.create!(title: data["title"], locale: "cs")

          if data["links"].present?
            data["links"].each do |link|
              if link["rails_path"].present?
                menu.menu_items.create!(rails_path: link["rails_path"], title: link["title"])
              elsif link["page_singleton_class"].present?
                menu.menu_items.create!(target: link["page_singleton_class"].constantize.instance, title: link["title"])
              end
            end
          end

          puts "Created #{klass}"
        else
          puts "Skipping existing #{klass}"
        end
      end
    end
  end
end
