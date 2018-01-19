# frozen_string_literal: true

require 'faker'

Folio::Atom.destroy_all
Folio::Node.destroy_all
Folio::Site.destroy_all
Folio::Account.destroy_all

site = Folio::Site.create!(title: 'Sinfin.digital',
                           domain: 'sinfin.localhost',
                           locale: 'cs',
                           locales: ['cs', 'en', 'de'],
                           email: 'info@sinfin.cz',
                           phone: '+420 123 456 789')

about = Folio::Page.create!(title: 'O nás',
                            site: site,
                            published: true)

reference = Folio::Category.create!(title: 'Reference',
                                    site: site,
                                    published: true,
                                    published_at: 1.day.ago)
Folio::Page.create!(title: 'Smart Cities', parent: reference, published: true)
Folio::Page.create!(title: 'Vyvolej.to', parent: reference, published: true)
Folio::Page.create!(title: 'Hidden', parent: reference, published: false)
Folio::Page.create!(title: 'DAM', parent: reference, published: true)

menu = Folio::Menu::Header.create!
Folio::MenuItem.create!(menu: menu,
                        title: 'Reference',
                        node: reference,
                        position: 0)
Folio::MenuItem.create!(menu: menu,
                        title: 'About',
                        node: about,
                        position: 1)

Folio::Account.create!(email: 'test@test.test',
                       password: 'test@test.test',
                       role: :superuser,
                       first_name: 'Test',
                       last_name: 'Dummy')

about_en = about.translate!(:en)
about_en.update(title: 'About', published: true)
about.translate!(:de)
