# frozen_string_literal: true

require_relative "lib/engine_llm/version"

Gem::Specification.new do |spec|
  spec.name          = "engine-llm"
  spec.version       = EngineLlm::VERSION
  spec.authors       = ["Eric Laquer"]
  spec.email         = ["LaquerEric@gmail.com"]

  spec.summary       = "LLM chat engine for Ecosystems"
  spec.description   = "Rails Engine providing multi-provider LLM chat UI with Raix 2.0, " \
                        "tab navigation, and settings management."
  spec.homepage      = "https://github.com/laquereric/engine-llm"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/laquereric/engine-llm"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "VERSION", "METADATA.yml", "LICENSE.txt", "Rakefile", "README.md"]
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 7.1"
  spec.add_dependency "view_component", ">= 4.0"
  spec.add_dependency "raix"
end
