# frozen_string_literal: true

namespace :blog do
  task idp_seed_dummy_blog: :environment do
    Rake::Task["developer_tools:idp_seed_dummy_images"].invoke
    images = Folio::File::Image.tagged_with("unsplash").to_a

    target_authors_count = 5
    target_topic_count = 5
    target_articles_count = 30

    if ENV["FORCE"]
      puts "Destroying all blog records as FORCE was passed"
      Dummy::Blog::Article.destroy_all
      Dummy::Blog::Author.destroy_all
      Dummy::Blog::Topic.destroy_all
    end

    Folio::Site.find_each do |site|
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
            Dummy::Blog::Topic.create!(title: Faker::Hipster.sentence(word_count: rand(1..3)),
                                       locale:,
                                       cover: images.sample,
                                       published: true,
                                       site:)
            print "."
          end

          puts "\nSeeded #{needed_topic_count} dummy blog topics for site #{site.slug} with #{locale} locale."
        end

        topics = Dummy::Blog::Topic.where(locale:).to_a

        if needed_authors_count == 0
          puts "Not seeding dummy blog authors for site #{site.slug} with #{locale} locale as there are #{authors_count} already."
        else
          puts "Need to seed #{needed_authors_count} dummy blog authors for site #{site.slug} with #{locale} locale."

          needed_authors_count.times do
            Dummy::Blog::Author.create!(first_name: Faker::Name.first_name,
                                        last_name: Faker::Name.last_name,
                                        locale:,
                                        cover: images.sample,
                                        published: true,
                                        site:)
            print "."
          end

          puts "\nSeeded #{needed_authors_count} dummy blog authors for site #{site.slug} with #{locale} locale."
        end

        authors = Dummy::Blog::Author.where(locale:).to_a

        if needed_articles_count == 0
          puts "Not seeding dummy blog articles for site #{site.slug} with #{locale} locale as there are #{articles_count} already."
        else
          puts "Need to seed #{needed_articles_count} dummy blog articles for site #{site.slug} with #{locale} locale."

          needed_articles_count.times do
            article = Dummy::Blog::Article.create!(title: Faker::Hipster.sentence(word_count: rand(1..3)),
                                                   perex: Faker::Hipster.paragraph,
                                                   locale:,
                                                   topics: topics.sample(rand(1..3)),
                                                   authors: authors.sample(rand(1..2)),
                                                   cover: images.sample,
                                                   site:,
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

          puts "\nSeeded #{needed_articles_count} dummy blog articles for site #{site.slug} with #{locale} locale."
        end
      end
    end
  end
end


