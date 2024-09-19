# frozen_string_literal: true

namespace :blog do
  task idp_seed_dummy_blog: :environment do
    Rake::Task["developer_tools:idp_seed_dummy_images"].invoke
    images = Folio::File::Image.tagged_with("unsplash").to_a

    if ENV["FORCE"]
      puts "Destroying all blog records as FORCE was passed"
      Dummy::Blog::Article.destroy_all
      Dummy::Blog::Author.destroy_all
      Dummy::Blog::Topic.destroy_all

      Dummy::Page::Blog::Articles::Index.find_each do |page|
        page.force_destroy = true
        page.destroy!
      end
    end

    Folio::Site.find_each do |site|
      unless Dummy::Page::Blog::Articles::Index.exists?(site:)
        page = Dummy::Page::Blog::Articles::Index.create!(title: "Blog",
                                                          site:,
                                                          published: true,
                                                          published_at: 1.minute.ago)

        locales = ::Rails.application.config.folio_using_traco ? site.locales : [nil]

        locales.each do |locale|
          Dummy::Atom::Listings::Blog::Articles::Index.create!(placement: page,
                                                       locale:,
                                                       position: 1)
        end

        puts "Seeded Dummy::Page::Blog::Articles::Index for site #{site.slug}"
      end

      Dummy::Blog.available_locales.each do |locale|
        authors_count = Dummy::Blog::Author.where(site:, locale:).count
        topics_count = Dummy::Blog::Author.where(site:, locale:).count
        articles_count = Dummy::Blog::Author.where(site:, locale:).count

        needed_authors_count = [0, 5 - authors_count].max
        needed_topic_count = [0, 5 - topics_count].max
        needed_articles_count = [0, 30 - articles_count].max

        if needed_topic_count == 0
          puts "Not seeding dummy blog topics for site #{site.slug} with #{locale} locale as there are #{topics_count} already."
        else
          puts "Need to seed #{needed_topic_count} dummy blog topics for site #{site.slug} with #{locale} locale."

          needed_topic_count.times do
            title = nil
            sanity = 1000

            while sanity > 0 && (title.nil? || Dummy::Blog::Topic.where(title:, locale:, site:).exists?)
              sanity -= 1
              title = Faker::Hipster.sentence(word_count: rand(1..3), random_words_to_add: 0)
            end

            Dummy::Blog::Topic.create!(title:,
                                       locale:,
                                       cover: images.sample,
                                       perex: Faker::Hipster.paragraph,
                                       published: true,
                                       site:)
            print "."
          end

          puts "\nSeeded #{needed_topic_count} dummy blog topics for site #{site.slug} with #{locale} locale."
        end

        topics = Dummy::Blog::Topic.by_site(site).where(locale:).to_a

        if needed_authors_count == 0
          puts "Not seeding dummy blog authors for site #{site.slug} with #{locale} locale as there are #{authors_count} already."
        else
          puts "Need to seed #{needed_authors_count} dummy blog authors for site #{site.slug} with #{locale} locale."

          needed_authors_count.times do
            social_links = Hash[Dummy::Blog::Author.social_link_sites.sample(rand(0..6)).map do |key|
              [key.to_s, "##{key}"]
            end]

            first_name = nil
            last_name = Faker::Name.last_name
            sanity = 1000

            while sanity > 0 && (first_name.nil? || Dummy::Blog::Author.where(first_name:, last_name:, site:, locale:).exists?)
              sanity -= 1
              first_name = Faker::Name.first_name
            end

            Dummy::Blog::Author.create!(first_name:,
                                        last_name:,
                                        locale:,
                                        perex: Faker::Hipster.paragraph,
                                        cover: images.sample,
                                        published: true,
                                        job: Faker::Hipster.sentence(word_count: rand(1..3), random_words_to_add: 0).delete_suffix("."),
                                        social_links:,
                                        site:)
            print "."
          end

          puts "\nSeeded #{needed_authors_count} dummy blog authors for site #{site.slug} with #{locale} locale."
        end

        authors = Dummy::Blog::Author.by_site(site).where(locale:).to_a

        if needed_articles_count == 0
          puts "Not seeding dummy blog articles for site #{site.slug} with #{locale} locale as there are #{articles_count} already."
        else
          puts "Need to seed #{needed_articles_count} dummy blog articles for site #{site.slug} with #{locale} locale."

          needed_articles_count.times do
            article = Dummy::Blog::Article.create!(title: Faker::Hipster.sentence(word_count: rand(1..3), random_words_to_add: 0),
                                                   perex: Faker::Hipster.paragraph,
                                                   locale:,
                                                   topics: topics.sample(rand(1..3)),
                                                   authors: authors.sample(rand(1..2)),
                                                   cover: images.sample,
                                                   site:,
                                                   published: true,
                                                   published_at: 1.day.ago)

            article.atoms.create(type: "Dummy::Atom::Contents::LeadParagraph",
                                 content: "<p>#{Faker::Hipster.paragraph}</p>",
                                 position: 1)

            article.atoms.create(type: "Dummy::Atom::Contents::Text",
                                 content: "<p>#{Faker::Hipster.paragraph}</p>",
                                 position: 2)

            article.atoms.create(type: "Dummy::Atom::Images::Single",
                                 cover: images.sample,
                                 position: 3)

            article.atoms.create(type: "Dummy::Atom::Contents::Text",
                                 content: "<p>#{Faker::Hipster.paragraph}</p>",
                                 position: 4)

            print "."
          end

          puts "\nSeeded #{needed_articles_count} dummy blog articles for site #{site.slug} with #{locale} locale."
        end
      end
    end
  end
end
