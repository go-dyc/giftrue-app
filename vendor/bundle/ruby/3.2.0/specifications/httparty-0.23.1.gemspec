# -*- encoding: utf-8 -*-
# stub: httparty 0.23.1 ruby lib

Gem::Specification.new do |s|
  s.name = "httparty".freeze
  s.version = "0.23.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["John Nunemaker".freeze, "Sandro Turriate".freeze]
  s.date = "2025-03-28"
  s.description = "Makes http fun! Also, makes consuming restful web services dead easy.".freeze
  s.email = ["nunemaker@gmail.com".freeze]
  s.executables = ["httparty".freeze]
  s.files = ["bin/httparty".freeze]
  s.homepage = "https://github.com/jnunemaker/httparty".freeze
  s.licenses = ["MIT".freeze]
  s.post_install_message = "When you HTTParty, you must party hard!".freeze
  s.required_ruby_version = Gem::Requirement.new(">= 2.7.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Makes http fun! Also, makes consuming restful web services dead easy.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<csv>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<multi_xml>.freeze, [">= 0.5.2"])
  s.add_runtime_dependency(%q<mini_mime>.freeze, [">= 1.0.0"])
end
