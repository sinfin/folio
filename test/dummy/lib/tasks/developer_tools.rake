# frozen_string_literal: true

namespace :developer_tools do
  task seed_singleton_pages: :environment do
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
      end
    end
  end
end
