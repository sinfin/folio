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
    create_menu_item = Proc.new do |menu, item_data, parent, position|
      mi = menu.menu_items.build(title: item_data["title"],
                                 rails_path: item_data["rails_path"],
                                 url: item_data["url"],
                                 position:)

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
            count = 0

            data["links"].each do |link|
              mi = create_menu_item.call(menu, link, nil, count += 1)

              if link["children"]
                link["children"].each do |child_link|
                  create_menu_item.call(menu, child_link, mi, count += 1)
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

  desc "Seed dummy unplash images"
  task idp_seed_dummy_images: :environment do
    Folio::Site.find_each do |site|
      %w[
        adrianna-geo-1rBg5YSi00c-unsplash.jpg
        birmingham-museums-trust-KfRUve5NtO8-unsplash.jpg
        boston-public-library-_f9cP4_unmg-unsplash.jpg
        british-library-gUDNK8NqYHk-unsplash.jpg
        europeana--kUYkiWWM6E-unsplash.jpg
        europeana-3bg0fd2uIds-unsplash.jpg
        europeana-4juaKkjUzqQ-unsplash.jpg
        europeana-6c43FgRt0Dw-unsplash.jpg
        europeana-H-4WME4eoOo-unsplash.jpg
        europeana-L9au-ZOs8WU-unsplash.jpg
        europeana-SMWPYQhVRuY-unsplash.jpg
        europeana-TjegK_z-0j8-unsplash.jpg
        europeana-tONMTB7h1TY-unsplash.jpg
        europeana-uS5LXujNOq4-unsplash.jpg
      ].each do |file_name|
        if Folio::File::Image.tagged_with("unsplash").exists?(site:, file_name: file_name.split(".").map(&:parameterize).join("."))
          print("s")
          next
        end

        src = "https://s3.eu-west-1.amazonaws.com/sinfin-staging/_unsplash/artwork/#{file_name}"

        Folio::File::Image.create!(file_url: src,
                                   tag_list: "unsplash, seed, artwork",
                                   site:)
        print(".")
      end
    end
  end
end
