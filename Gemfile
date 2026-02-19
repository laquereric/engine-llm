# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "rake", "~> 13.0"
gem "view_component"
gem "sqlite3", ">= 2.1"

group :development, :test do
  gem "rspec-rails", "~> 6.0"
  gem "factory_bot_rails", "~> 6.0"
  gem "rubocop", "~> 1.21"
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "rubocop-rails-omakase", require: false
end

eco_root = __dir__
eco_root = File.dirname(eco_root) until File.exist?("#{eco_root}/Gemfile.eco")
eval_gemfile "#{eco_root}/Gemfile.eco"

eco_gem "ecosystem-citizen"

# Transitive deps of ecosystem-citizen need path refs until gems are published
eco_gem "service-exception"
eco_gem "biological-it"
eco_gem "service-protege"
eco_gem "json-rpc-ld-client", require: "json_rpc_ld/client"
eco_gem "json-rpc-ld-server", require: "json_rpc_ld/server"
eco_gem "ecosystem-manager-base"
eco_gem "ecosystems-protege-launch"
eco_gem "llm_engine"

eco_gem "engine-design-system"
eco_gem "heartbeat"
eco_gem "platform"
