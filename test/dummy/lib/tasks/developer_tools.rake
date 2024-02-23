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
      puts "Seeding dummy images for site #{site.slug}."

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

      puts "\nSeeded dummy images for site #{site.slug}."
    end
  end

  namespace :blog do
    task idp_seed_dummy_blog: :environment do
      Rake::Task["developer_tools:idp_seed_dummy_images"].invoke
      images = Folio::File::Image.tagged_with("unsplash").to_a

      topic_count = 5
      article_count = 30

      if ENV["FORCE"]
        puts "Destroying all articles and topics as FORCE was passed"
        Dummy::Blog::Article.destroy_all
        Dummy::Blog::Topic.destroy_all
      end

      Folio::Site.find_each do |site|
        Dummy::Blog.available_locales.each do |locale|
          puts "Seeding #{topic_count} dummy blog topics for site #{site.slug} with #{locale} locale."

          topic_count.times do
            Dummy::Blog::Topic.create!(title: Faker::Hipster.sentence(word_count: rand(1..3)),
                                       locale:,
                                       cover: images.sample,
                                       published: true)
            print "."
          end

          puts "\nSeeded #{topic_count} dummy blog topics for site #{site.slug} with #{locale} locale."

          topics = Dummy::Blog::Topic.where(locale:).to_a

          puts "Seeding #{article_count} dummy blog articles for site #{site.slug} with #{locale} locale."

          article_count.times do
            article = Dummy::Blog::Article.create!(title: Faker::Hipster.sentence(word_count: rand(1..3)),
                                                   perex: Faker::Hipster.paragraph,
                                                   locale:,
                                                   topics: topics.sample(rand(1..3)),
                                                   cover: images.sample,
                                                   published: true,
                                                   published_at: 1.day.ago)

            article.atoms.create(type: "Dummy::Atom::Text",
                                 content: "<p>#{Faker::Hipster.paragraph}</p>",
                                 position: 1)

            article.atoms.create(type: "Dummy::Atom::Images::Single",
                                 cover: images.sample,
                                 position: 2)

            article.atoms.create(type: "Dummy::Atom::Text",
                                 content: "<p>#{Faker::Hipster.paragraph}</p>",
                                 position: 3)

            print "."
          end

          puts "\nSeeded #{article_count} dummy blog articles for site #{site.slug} with #{locale} locale."
        end
      end
    end
  end

  namespace :atoms do
    desc "Screenshot atoms from atoms_showcase"
    task screenshot: :environment do
      require "selenium-webdriver"

      root_data = YAML.load_file(Rails.root.join("data/atoms_showcase.yml"))

      options = Selenium::WebDriver::Chrome::Options.new
      options.add_argument("--headless")
      options.add_argument("--window-size=1200,800")

      driver = Selenium::WebDriver.for(:chrome, options:)

      FileUtils.mkdir_p(Rails.root.join("public/images/atoms"))

      root_data["atoms"].keys.each do |class_name|
        driver.navigate.to "http://localhost:3000/atoms/?atom=#{class_name}&screenshot=1"

        file_name = "#{class_name.underscore.gsub('/', '-')}.webp"
        webp_file_path = Rails.root.join("public/images/atoms/#{file_name}")

        Dir.mktmpdir do |dir|
          tmp_png_path = "#{dir}/screenshot.png"
          tmp_webp_path = "#{dir}/screenshot.webp"

          driver.save_screenshot(tmp_png_path)

          system "cwebp -q 85 #{tmp_png_path} -o #{tmp_webp_path}"

          FileUtils.cp tmp_webp_path, webp_file_path
        end
      end

      driver.quit
    end
  end
end
