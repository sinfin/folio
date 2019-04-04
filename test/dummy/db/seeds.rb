# frozen_string_literal: true

require 'faker'

def force_destroy(klass)
  klass.find_each { |o| o.try(:force_destroy=, true); o.destroy! }
end

Folio::Atom::Base.destroy_all
Folio::Account.destroy_all
Folio::Lead.destroy_all
Folio::File.destroy_all
force_destroy Folio::Menu
force_destroy Folio::Page
force_destroy Folio::Site

def unsplash_pic(square = false)
  image = Folio::Image.new
  scale = 0.5 + rand / 2
  image.file_url = "https://picsum.photos/#{scale * 2560}/#{square ? scale * 2560 : scale * 1440}/?random"
  image.save!
  image
end

def file_pic(file_instance)
  image = Folio::Image.new
  image.file = file_instance
  image.save!
  image
end

2.times { unsplash_pic }

Folio::Site.create!(title: 'Sinfin.digital',
                    domain: 'sinfin.localhost',
                    locale: 'cs',
                    locales: ['cs', 'en', 'de'],
                    email: 'info@sinfin.cz',
                    phone: '+420 123 456 789',
                    social_links: {
                      facebook: 'https://www.facebook.com/',
                      instagram: 'https://www.instagram.com/',
                      twitter: 'https://www.twitter.com/',
                    })

about = Folio::Page.create!(title: 'O nás',
                            published: true,
                            published_at: 1.month.ago)
about.cover = unsplash_pic
3.times { about.images << unsplash_pic }
about.image_placements.each { |ip|
  name = Faker::Name.name
  ip.update_attributes!(alt: name, title: "Portrait of #{name}")
}


night_sky = Folio::Page.create!(title: 'Noční obloha', published: true, published_at: 1.month.ago, locale: :cs)
night_photo = File.new(Rails.root.join('..', 'fixtures', 'folio', 'night.jpg'))
night_sky.cover = file_pic(night_photo)
1.times { night_sky.images << file_pic(night_photo) }
# TODO: Atoms


reference = Folio::Page.create!(title: 'Reference',
                                published: true,
                                published_at: 1.day.ago)
Folio::Page.create!(title: 'Smart Cities', published: true, published_at: 1.month.ago)
Folio::Page.create!(title: 'Vyvolej.to', published: true, published_at: 1.month.ago)
Folio::Page.create!(title: 'Hidden', published: false)
Folio::Page.create!(title: 'DAM', published: true)

menu = Folio::Menu::Page.create!(locale: :cs)

Folio::MenuItem.create!(menu: menu,
                        title: 'Reference',
                        target: reference,
                        position: 0)

Folio::MenuItem.create!(menu: menu,
                        title: 'About',
                        target: about,
                        position: 1)

if Rails.env.development?
  Folio::Account.create!(email: 'test@test.test',
                         password: 'test@test.test',
                         role: :superuser,
                         first_name: 'Test',
                         last_name: 'Dummy')
end

nestable_menu = Dummy::Menu::Nestable.create!(locale: :cs)
Folio::MenuItem.create!(menu: nestable_menu,
                        title: 'Reference',
                        target: reference,
                        position: 0)
wrap = Folio::MenuItem.create!(menu: nestable_menu,
                               title: 'Wrap',
                               position: 1)
[reference, about].each do |target|
  Folio::MenuItem.create!(menu: nestable_menu,
                          target: target,
                          parent: wrap)
end

Folio::Lead.create!(name: 'Test lead',
                    email: 'test@lead.test',
                    note: 'Hello',
                    additional_data: { test: 'test', boolean: false })
