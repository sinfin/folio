# frozen_string_literal: true

require "faker"
require "resolv-replace"

if Rails.env.development?
  ActiveJob::Base.queue_adapter = :inline
end

def destroy_all(klass)
  puts "Destroying #{klass}"
  klass.destroy_all
  puts "Destroyed #{klass}"
end

def force_destroy_all(klass)
  puts "Destroying #{klass}"
  klass.find_each { |o| o.try(:force_destroy=, true); o.destroy! }
  puts "Destroyed #{klass}"
end

destroy_all Folio::Atom::Base
destroy_all Folio::FilePlacement::Base
destroy_all Folio::File
destroy_all Folio::Lead
destroy_all Folio::User

force_destroy_all Folio::Menu
destroy_all Folio::Page
destroy_all Folio::Site

destroy_all Dummy::Blog::Article
destroy_all Dummy::Blog::Topic

puts "Creating Folio::Site"
Folio::Site.create!(title: "Sinfin.digital",
                    domain: "sinfin.localhost",
                    locale: "cs",
                    locales: ["cs", "en", "de"],
                    type: "Folio::Site",
                    email: "info@sinfin.cz",
                    phone: "+420 123 456 789",
                    address: "Ulice 100, 14000 Praha 4",
                    copyright_info_source: "© Sinfin.digital {YEAR}",
                    available_user_roles: %w[administrator manager],
                    social_links: {
                      facebook: "https://www.facebook.com/",
                      instagram: "https://www.instagram.com/",
                      twitter: "https://www.twitter.com/",
                      linkedin: "https://www.linkedin.com/",
                      youtube: "https://www.youtube.com/",
                    })
puts "Created Folio::Site"

puts "Creating Folio::User test@test.test (superadmin)"
puts("Should call folio:seed_test_account task")
Folio::User.create!(first_name: "Test",
                    last_name: "Test",
                    email: "test@test.test",
                    password: "test@test.test",
                    confirmed_at: Time.current,
                    superadmin: true)
puts "Created Folio::User test@test.test (superadmin)"

puts "Creating Dummy::Menu::Nestable"
menu = Dummy::Menu::Nestable.create!(locale: :cs, title: "Nestable", site: ::Folio.main_site)

root = Folio::MenuItem.create!(menu:,
                               title: "Reference",
                               url: "./",
                               position: 0)

child = Folio::MenuItem.create!(menu:,
                                title: "Podreference",
                                url: "./",
                                position: 1,
                                parent: root)

Folio::MenuItem.create!(menu:,
                        title: "Podreference",
                        url: "./",
                        position: 2,
                        parent: child)

Folio::MenuItem.create!(menu:,
                        title: "About",
                        url: "./",
                        position: 3)
puts "Created Dummy::Menu::Nestable"

puts "Creating Dummy::Menu::Stylable"
menu = Dummy::Menu::Stylable.create!(locale: :cs, title: "Stylable", site: ::Folio.main_site)

Folio::MenuItem.create!(menu:,
                        title: "Reference",
                        url: "./",
                        position: 0)

Folio::MenuItem.create!(menu:,
                        title: "About red",
                        url: "./",
                        position: 1,
                        style: "red")

Folio::MenuItem.create!(menu:,
                        title: "About",
                        url: "./",
                        position: 1)
puts "Created Dummy::Menu::Stylable"

puts "Creating Dummy::Menu::Header"
menu = Dummy::Menu::Header.create!(locale: :cs, title: "Header", site: ::Folio.main_site)

position = 0

Folio::MenuItem.create!(menu:,
                        title: "UI Kit",
                        url: "/ui",
                        position: position += 1)

Folio::MenuItem.create!(menu:,
                        title: "Atoms",
                        url: "/atoms",
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

menu = Dummy::Menu::Footer.create!(locale: :cs, title: "Footer", site: ::Folio.main_site)

3.times do |i|
  Folio::MenuItem.create!(menu:,
                          title: "Footer link #{i + 1}",
                          url: "/",
                          position: i + 1)
end

puts "Created Dummy::Menu::Footer"

puts "Creating Dummy::HomePage"

