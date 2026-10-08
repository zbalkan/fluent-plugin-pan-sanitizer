# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "fluent-plugin-pan-sanitizer"
  spec.version       = "0.0.2"
  spec.authors       = ["Hiroaki Sano", "Zafer Balkan"]
  spec.email         = ["hiroaki.sano.9stories@gmail.com"]

  spec.summary       = %q{Fluentd filter plugin to anonymize credit card numbers.}
  spec.homepage      = "https://github.com/zbalkan/fluent-plugin-pan-sanitizer"
  spec.license       = "Apache-2.0"
  spec.required_ruby_version = ">= 2.7"

  spec.files         = `git ls-files`.split("\n")
  spec.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  spec.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "test-unit"

  spec.add_runtime_dependency "fluentd", ">= 1.16", "< 2.0"
end
