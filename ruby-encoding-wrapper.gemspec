Gem::Specification.new do |s|
  s.name            = "ruby-encoding-wrapper"
  s.version         = "0.1.0"
  s.author          = ["Mikhailov Anatoly", "Tsech Edward", "Anton Zaytsev"]
  s.email           = "info@antonzaytsev.com"
  s.homepage        = "https://github.com/mikhailov/ruby-encoding-wrapper"
  s.description     = "Simple wrapper for encoding.com API based on ruby."

  s.files           = Dir["{lib,test}/**/*"] + Dir["[A-Z]*"] + ["init.rb"]
  s.require_paths   = ["lib"]

  s.rubyforge_project = s.name
  s.required_rubygems_version = ">= 1.3.4"

  s.add_dependency('nokogiri', '~> 1.0')
end