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

  task idp_seed_page_titles: :environment do
    Rails.logger.silence do
      if File.exist?(Rails.root.join("data/seed/page_titles.yml"))
        data = YAML.load_file(Rails.root.join("data/seed/page_titles.yml"))

        data.each do |attrs|
          if Folio::Page.exists?(title: attrs["title"])
            puts "Skipping existing #{attrs["title"]}"
            next
          else
            record = Folio::Page.create!(title: attrs["title"],
                                         perex: attrs["perex"],
                                         published: true,
                                         published_at: 1.minute.ago)

            if attrs["atoms"].present?
              attrs["atoms"].each do |attrs|
                record.atoms.create!(attrs)
              end
            end

            puts "Created #{attrs["title"]}"
          end
        end
      end
    end
  end

  task idp_seed_singleton_menus: :environment do
    create_menu_item = Proc.new do |menu, item_data, parent|
      mi = menu.menu_items.build(title: item_data["title"],
                                 rails_path: item_data["rails_path"])

      if item_data["page_singleton_class"].present?
        mi.target = item_data["page_singleton_class"].constantize.instance
      end

      if item_data["page_title"].present?
        mi.target = Folio::Page.find_by!(title: item_data["page_title"])
      end

      if parent
        mi.parent = parent
      end

      mi.save!

      mi
    end

    Rails.logger.silence do
      Dir.glob(Rails.root.join("data/seed/menus/*.yml")).each do |yaml_path|
        data = YAML.load_file(yaml_path)
        klass = data["type"].constantize

        if !klass.exists? || ENV["FORCE"] || ENV["FORCE_SINGLETON"] == klass.to_s
          klass.find_each { |o| o.try(:force_destroy=, true); o.destroy! }

          menu = klass.create!(title: data["title"], locale: "en")

          if data["links"].present?
            data["links"].each do |link|
              mi = create_menu_item.call(menu, link, nil)

              if link["children"]
                link["children"].each do |child_link|
                  create_menu_item.call(menu, child_link, mi)
                end
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