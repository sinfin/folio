# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

Folio::Site.destroy_all
Folio::Node.destroy_all
Folio::File.destroy_all
Folio::Account.destroy_all

site = Folio::Site.create!(title: 'Sinfin.digital', domain: 'sinfin.localhost', locale: 'cs', locales: ['en', 'de', 'es'], google_analytics_tracking_code: 'UA-8111656-1')

about = Folio::Page.create!(title: 'O nás', site: site, published: true, published_at: 1.day.ago)
# about.translations << Folio::PageTranslation.create!(original_id: about.id, title: "About us", locale: :en, site: site)
# about.translations << Folio::PageTranslation.create!(original_id: about.id, title: "Nosotros", locale: :es, site: site)
site.nodes << about

reference = Folio::Category.create!(title: 'Reference', site: site, published: true, published_at: 1.day.ago)
site.nodes << reference
pagesc = Folio::Page.create!(title: 'Smart Cities', parent: reference, published: true, published_at: 1.day.ago)
Folio::Page.create!(title: 'Vyvolej.to', parent: reference, published: true, published_at: Time.now, featured: true)
Folio::Page.create!(title: 'Hidden', parent: reference, published: false, published_at: Time.now, featured: true)
Folio::Page.create!(title: 'DAM', parent: reference, published: true, published_at: 1.month.since)

Folio::Account.create!(email: 'test@test.com', password: '123456', role: :superuser, first_name: 'Test', last_name: 'Dummy')

img1 = Folio::Image.create!(file: open('https://unsplash.com/photos/smWTOhdPvJc/download?force=true'), file_name: 'table.png')
img2 = Folio::Image.create!(file: open('https://unsplash.com/photos/9gnXVOgo_-I/download?force=true'), file_name: 'earth_001.jpg')
img3 = Folio::Image.create!(file: open('https://unsplash.com/photos/DlnK1KOREds/download?force=true'), file_name: 'landscape.png')
img4 = Folio::Image.create!(file: open('https://unsplash.com/photos/TswcU9rBUWY/download?force=true'), file_name: 'yoga.jpg')
doc1 = Folio::Document.create!(file: open('https://unsplash.com/photos/TswcU9rBUWY/download?force=true'), file_name: 'doc.docx')

about.file_placements << Folio::FilePlacement.new(file: img1, caption: 'Image 1')
about.file_placements << Folio::FilePlacement.new(file: img2, caption: 'Image 2')
about.file_placements << Folio::FilePlacement.new(file: img3, caption: 'Image 3')
about.file_placements << Folio::FilePlacement.new(file: doc1, caption: 'Doc 1')
about.file_placements << Folio::FilePlacement.new(file: img4, caption: 'Image 4')
pagesc.file_placements << Folio::FilePlacement.new(file: img2, caption: 'Image 2a')

about.translate!(:en)
about.translate!(:de)
