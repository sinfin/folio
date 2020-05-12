# frozen_string_literal: true

namespace :folio do
  namespace :pg do
    task insert_folio_unaccent_into_schema: :environment do
      path = File.join(ActiveRecord::Tasks::DatabaseTasks.db_dir, 'schema.rb')
      file = File.read(path).sub(/(enable_extension "unaccent"\n)/, "\\1\n  create_folio_unaccent\n")
      File.write(path, file)
    end
  end
end

Rake::Task['db:schema:dump'].enhance do
  if Rake::Task.task_defined?('app:folio:pg:insert_folio_unaccent_into_schema')
    Rake::Task['app:folio:pg:insert_folio_unaccent_into_schema'].invoke
  else
    Rake::Task['folio:pg:insert_folio_unaccent_into_schema'].invoke
  end
end
