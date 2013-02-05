class JasmineCoverageRailtie < Rails::Railtie
  rake_tasks do
    load "tasks/jasmine_coverage.rake"
  end
end