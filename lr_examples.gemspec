require_relative "lib/lr_examples/version"

Gem::Specification.new do |spec|
  spec.name = "lr_examples"
  spec.version = LrExamples::VERSION
  spec.authors = ["Benoit Hiller"]
  spec.email = ["benoit.hiller@gmail.com"]

  spec.summary = "LR parsing example code"
  spec.homepage = "https://github.com/benoithiller/lr_examples"
  spec.required_ruby_version = ">= 3.4"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.require_paths = ["lib"]
end
