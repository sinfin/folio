# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

Folio::Site.destroy_all
Folio::Node.destroy_all


site = Folio::Site.create!(title: "Sinfin.digital", domain: "sinfin.localhost", locale: "cs", locales: ["en", "de", "es"])

about = Folio::Page.create!(title: "O nás", site: site)
# about.translations << Folio::PageTranslation.create!(original_id: about.id, title: "About us", locale: :en, site: site)
# about.translations << Folio::PageTranslation.create!(original_id: about.id, title: "Nosotros", locale: :es, site: site)
site.nodes << about

reference = Folio::Category.create!(title: "Reference", site: site)
site.nodes << reference
Folio::Page.create!(title: "Smart Cities", parent: reference)
Folio::Page.create!(title: "Vyvolej.to", parent: reference)
Folio::Page.create!(title: "DAM", parent: reference)
