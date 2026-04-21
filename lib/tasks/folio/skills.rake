# frozen_string_literal: true

namespace :folio do
  namespace :skills do
    desc "Copy Folio AI skills into the host app and update AGENTS.md"
    task copy: :environment do
      source_dir = Folio::Engine.root.join(".skills")
      target_dir = Rails.root.join(".skills")

      unless source_dir.exist?
        puts "No .skills/ directory found in Folio engine."
        next
      end

      FileUtils.mkdir_p(target_dir)

      skills = []
      Dir.glob(source_dir.join("folio-*/SKILL.md")).sort.each do |skill_md_path|
        skill_name = File.basename(File.dirname(skill_md_path))
        target_path = target_dir.join(skill_name)
        FileUtils.mkdir_p(target_path)
        FileUtils.cp(skill_md_path, target_path)

        frontmatter = File.read(skill_md_path).match(/\A---\n(.+?\n)---/m)&.[](1)
        next unless frontmatter

        parsed = YAML.safe_load(frontmatter)
        next unless parsed&.dig("name")

        skills << { name: parsed["name"], description: parsed["description"] }
      end

      if skills.empty?
        puts "No folio-* skills found in #{source_dir}."
        next
      end

      puts "Copied #{skills.size} Folio skills to #{target_dir}:"
      skills.each { |s| puts "  #{s[:name]}" }

      agents_path = Rails.root.join("AGENTS.md")

      unless agents_path.exist?
        puts "AGENTS.md not found at #{agents_path}, skipping table update."
        next
      end

      rows = skills.map { |s| "| **#{s[:name]}** | #{s[:description]} |" }
      section = <<~MD
        ## Folio Skills

        Copied from Folio engine. Do not edit manually — regenerate with `rails folio:skills:copy`.

        | Skill | Description |
        |-------|-------------|
      MD
      section += rows.join("\n") + "\n"

      content = agents_path.read

      if content.match?(/^##\s+Folio Skills\b/i)
        content.sub!(/^##\s+Folio Skills\b[^\n]*\n.*?(?=\n##\s|\z)/mi, section.chomp)
        puts "Updated Folio Skills section in #{agents_path}"
      else
        content = content.chomp + "\n\n" + section
        puts "Added Folio Skills section to #{agents_path}"
      end

      agents_path.write(content.sub(/\n*\z/, "\n"))
    end
  end
end
