# -*- encoding: utf-8 -*-
# stub: gemini-ai 4.3.0 ruby ports/dsl

Gem::Specification.new do |s|
  s.name = "gemini-ai".freeze
  s.version = "4.3.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://rubygems.org", "homepage_uri" => "https://github.com/gbaptista/gemini-ai", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/gbaptista/gemini-ai" } if s.respond_to? :metadata=
  s.require_paths = ["ports/dsl".freeze]
  s.authors = ["gbaptista".freeze]
  s.date = "2025-07-09"
  s.description = "A Ruby Gem for interacting with Gemini through Vertex AI, Generative Language API, or AI Studio, Google's generative AI services.".freeze
  s.homepage = "https://github.com/gbaptista/gemini-ai".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.1.0".freeze)
  s.rubygems_version = "3.3.3".freeze
  s.summary = "Interact with Google's Gemini AI.".freeze

  s.installed_by_version = "3.6.2".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<event_stream_parser>.freeze, ["~> 1.0".freeze])
  s.add_runtime_dependency(%q<faraday>.freeze, ["~> 2.13".freeze, ">= 2.13.2".freeze])
  s.add_runtime_dependency(%q<faraday-typhoeus>.freeze, ["~> 1.1".freeze])
  s.add_runtime_dependency(%q<googleauth>.freeze, ["~> 1.8".freeze])
  s.add_runtime_dependency(%q<typhoeus>.freeze, ["~> 1.4".freeze, ">= 1.4.1".freeze])
end
