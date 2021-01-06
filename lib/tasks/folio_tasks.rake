# frozen_string_literal: true

namespace :folio do
  task seed_test_account: :environment do
    if Rails.env.development?
      if Folio::Account.find_by(email: "test@test.test")
        puts "Account test@test.test already exists."
      else
        Folio::Account.create!(email: "test@test.test",
                               password: "test@test.test",
                               role: :superuser,
                               first_name: "Test",
                               last_name: "Dummy")
        puts "Created test@test.test account."
      end
    end
  end

  task seed_blog: :environment do
    require "faker"

    images = Folio::Image.tagged_with('seed')

    if images.blank?
      images = 3.times.map do
        image = Folio::Image.new
        scale = 0.5 + rand / 2
        w = (scale * 2560).to_i
        h = (scale * 1440).to_i
        image.file_url = "https://picsum.photos/#{w}/#{h}/?random"
        image.tag_list = "seed, unplash"
        image.save!
        image
      end
    end

    application_module = Rails.application.class.parent
    article_klass = "#{application_module}::Blog::Article".constantize
    category_klass = "#{application_module}::Blog::Category".constantize
    page_klass = "#{application_module}::Page::Blog".constantize

    if Rails.env.development?
      category_klass.destroy_all
      article_klass.destroy_all
    end

    if page_klass.exists?
      page = page_klass.instance
    else
      page = page_klass.create!(published: true, published_at: 1.minute.ago, title: "Blog")
    end

    page.update!(perex: nil, published: true, published_at: 1.minute.ago)
    page.atoms.destroy_all

    locales = "#{application_module}::Blog".constantize.available_locales

    locales.each do |locale|
      categories = 5.times.map do |i|
        category_klass.create!(locale: locale,
                               title: Faker::Hipster.words(number: rand(1..4), supplemental: false).join(' ').capitalize,
                               cover: images.sample,
                               published: !i.zero?,
                               featured: i > 1)
      end

      25.times do |i|
        article_klass.create!(locale: locale,
                              title: Faker::Hipster.sentence,
                              perex: Faker::Hipster.paragraph,
                              cover: images.sample,
                              primary_category: (categories + [nil]).sample,
                              categories: categories.sample(rand(0..categories.size)),
                              published: !i.zero?,
                              published_at: Time.zone.now - rand(0..30).days - rand(0..500).minutes)
      end

      if locales.size > 1
        atoms = page.atoms(locale)
        atom_locale = locale
      else
        atoms = page.atoms
        atom_locale = nil
      end

      position = 0

      Notesvilla::Atom::Blog::Articles::Latest.create!(position: position += 1,
                                                       placement: page,
                                                       locale: atom_locale)

      featured_categories = category_klass.all.sample(2)

      Notesvilla::Atom::Blog::Categories::LatestArticles.create!(position: position += 1,
                                                                 placement: page,
                                                                 locale: atom_locale,
                                                                 category: featured_categories.first,
                                                                 background: true)

      Notesvilla::Atom::Blog::Categories::Featured.create!(position: position += 1,
                                                           placement: page,
                                                           locale: atom_locale,
                                                           title: 'Featured topics')

      Notesvilla::Atom::Blog::Categories::LatestArticles.create!(position: position + 1,
                                                                 placement: page,
                                                                 locale: atom_locale,
                                                                 category: featured_categories.second)
    end
  end

  namespace :upgrade do
    task atom_document_placements: :environment do
      ids = []

      Folio::Atom.types.each do |type|
        if type::STRUCTURE[:document] && !type::STRUCTURE[:documents]
          type.includes(:document_placements).each do |atom|
            ids << atom.document_placements.pluck(:id)
          end
        end
      end

      Folio::FilePlacement::Document.where(id: ids)
                                    .update_all(type: "Folio::FilePlacement::SingleDocument")
    end

    task reset_file_file_placements_size: :environment do |t|
      Rails.logger.silence do
        Folio::File.where(file_placements_size: nil).find_each do |file|
          file.update_file_placements_size!
          print(".")
        end
      end
    end
  end
end
