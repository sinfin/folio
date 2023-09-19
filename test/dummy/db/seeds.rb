# frozen_string_literal: true

require "faker"

if Rails.env.development?
  ActiveJob::Base.queue_adapter = :inline
end

def destroy_all(klass)
  puts "Destroying #{klass}"
  klass.destroy_all
  puts "Destroyed #{klass}"
end

def force_destroy(klass)
  puts "Destroying #{klass}"
  klass.find_each { |o| o.try(:force_destroy=, true); o.destroy! }
  puts "Destroyed #{klass}"
end

destroy_all Folio::Atom::Base
destroy_all Folio::Account
destroy_all Folio::Lead
destroy_all Folio::File
force_destroy Folio::Menu
force_destroy Folio::Page
force_destroy Folio::Site

destroy_all Dummy::Blog::Article
destroy_all Dummy::Blog::Topic

def unsplash_pic(square = false)
  puts "Creating unsplash pic"

  image = Folio::File::Image.new
  scale = 0.5 + rand / 2
  w = (scale * 2560).to_i
  h = (square ? scale * 2560 : scale * 1440).to_i
  image.file_url = "https://picsum.photos/#{w}/#{h}/?random"
  image.tag_list = "unsplash, seed"
  image.file_name = "unsplash.jpg"
  image.file_width = w
  image.file_height = h
  image.save!

  puts "Created unsplash pic"

  image
end

def file_pic(file_instance)
  puts "Creating file pic"

  image = Folio::File::Image.new
  image.file = file_instance
  image.save!

  puts "Created file pic"

  image
end

2.times { unsplash_pic }

puts "Creating Folio::Site"
Folio::Site.create!(title: "Sinfin.digital",
                    domain: "sinfin.localhost",
                    locale: "cs",
                    locales: ["cs", "en", "de"],
                    email: "info@sinfin.cz",
                    phone: "+420 123 456 789",
                    copyright_info_source: "© Sinfin.digital {YEAR}",
                    social_links: {
                      facebook: "https://www.facebook.com/",
                      instagram: "https://www.instagram.com/",
                      twitter: "https://www.twitter.com/",
                      linkedin: "https://www.linkedin.com/",
                      youtube: "https://www.youtube.com/",
                    })
puts "Created Folio::Site"

puts "Creating about page"
about = Folio::Page.create!(title: "O nás",
                            published: true,
                            published_at: 1.month.ago)
about.cover = Folio::File::Image.first
about.image_placements.each { |ip|
  name = "Lorem Ipsum"
  ip.update_attributes!(alt: name, title: "Portrait of #{name}")
}
puts "Created about page"

puts "Creating more pages"
night_sky = Folio::Page.create!(title: "Noční obloha", published: true, published_at: 1.month.ago, locale: :cs)
night_photo = File.new(Folio::Engine.root.join("test/fixtures/folio/photos/night.jpg"))
night_sky.cover = file_pic(night_photo)
1.times { night_sky.images << file_pic(night_photo) }

reference = Folio::Page.create!(title: "Reference",
                                published: true,
                                published_at: 1.day.ago)
Folio::Page.create!(title: "Smart Cities", published: true, published_at: 1.month.ago)
vyvolejto = Folio::Page.create!(title: "Vyvolej.to", published: true, published_at: 1.month.ago)
iptc_test = File.new(Folio::Engine.root.join("test/fixtures/folio/photos/downsized-exif-samples/jpg/tests/46_UnicodeEncodeError.jpg"))
vyvolejto.cover = file_pic(iptc_test)

Folio::Page.create!(title: "Hidden", published: false)
Folio::Page.create!(title: "DAM", published: true)
puts "Created more pages"

puts "Creating Dummy::Menu::Nestable"
menu = Dummy::Menu::Nestable.create!(locale: :cs, title: "Nestable")

root = Folio::MenuItem.create!(menu:,
                               title: "Reference",
                               target: reference,
                               position: 0)

child = Folio::MenuItem.create!(menu:,
                                title: "Podreference",
                                target: reference,
                                position: 1,
                                parent: root)

Folio::MenuItem.create!(menu:,
                        title: "Podreference",
                        target: reference,
                        position: 2,
                        parent: child)

Folio::MenuItem.create!(menu:,
                        title: "About",
                        target: about,
                        position: 3)
puts "Created Dummy::Menu::Nestable"

puts "Creating Dummy::Menu::Stylable"
menu = Dummy::Menu::Stylable.create!(locale: :cs, title: "Stylable")

Folio::MenuItem.create!(menu:,
                        title: "Reference",
                        target: reference,
                        position: 0)

Folio::MenuItem.create!(menu:,
                        title: "About red",
                        target: about,
                        position: 1,
                        style: "red")

Folio::MenuItem.create!(menu:,
                        title: "About",
                        target: about,
                        position: 1)
puts "Created Dummy::Menu::Stylable"

puts "Creating Dummy::Menu::Header"
menu = Dummy::Menu::Header.create!(locale: :cs, title: "Header")

position = 0

Folio::MenuItem.create!(menu:,
                        title: "UI Kit",
                        url: "/ui",
                        position: position += 1)

Folio::MenuItem.create!(menu:,
                        title: "Atoms",
                        url: "/folio/ui/atoms",
                        position: position += 1)

Folio::MenuItem.create!(menu:,
                        title: "Blog",
                        url: "/blog",
                        position: position += 1)

mi = Folio::MenuItem.create!(menu:,
                             title: "Nestable non-link",
                             position: position += 1)

3.times do |i|
  Folio::MenuItem.create!(menu:,
                          title: "Child #{i + 1}",
                          url: "/",
                          position: i + 1,
                          parent: mi)
end

mi = Folio::MenuItem.create!(menu:,
                             title: "Nestable link",
                             url: "/",
                             position: position += 1)

3.times do |i|
  Folio::MenuItem.create!(menu:,
                          title: "Child #{i + 1}",
                          url: "/",
                          position: i + 1,
                          parent: mi)
end

Folio::MenuItem.create!(menu:,
                        title: "Another link",
                        url: "#another-link",
                        position: position += 1)

Folio::MenuItem.create!(menu:,
                        title: "Another link",
                        url: "#another-link",
                        position: position += 1)

Folio::MenuItem.create!(menu:,
                        title: "Another link",
                        url: "#another-link",
                        position: position += 1)

Folio::MenuItem.create!(menu:,
                        title: "Another link",
                        url: "#another-link",
                        position: position += 1)

Folio::MenuItem.create!(menu:,
                        title: "Another link",
                        url: "#another-link",
                        position: position + 1)

puts "Created Dummy::Menu::Header"

puts "Creating Dummy::Menu::Footer"

menu = Dummy::Menu::Footer.create!(locale: :cs, title: "Footer")

3.times do |i|
  Folio::MenuItem.create!(menu:,
                          title: "Footer link #{i + 1}",
                          url: "/",
                          position: i + 1)
end

puts "Created Dummy::Menu::Footer"

images = Folio::File::Image.tagged_with("unsplash").to_a

puts "Creating Dummy::Blog::Topic"

topics = 5.times.map do
  topic = Dummy::Blog::Topic.create!(locale: "cs",
                                     published: true,
                                     title: Faker::Hipster.words(number: rand(1..3)).join(" ").capitalize,
                                     cover: images.sample)

  print(".")

  topic
end

puts "\nCreated Dummy::Blog::Topic"

puts "Creating Dummy::Blog::Article"

20.times do |i|
  Dummy::Blog::Article.create!(locale: "cs",
                               published: true,
                               title: Faker::Hipster.words(number: rand(1..3)).join(" ").capitalize,
                               perex: Faker::Hipster.sentence,
                               cover: images.sample,
                               topics: topics.sample(rand(1..topics.size)),
                               published_at: Time.zone.now - i.days - i.hours - i.minutes)
  print(".")
end

puts "\nCreated Dummy::Blog::Article"

if Rails.env.development?
  puts "Creating test@test.test account"

  Folio::Account.create!(email: "test@test.test",
                         password: "test@test.test",
                         roles: %w[superuser],
                         first_name: "Test",
                         last_name: "Dummy")

  puts "Created test@test.test account"
end
