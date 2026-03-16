# frozen_string_literal: true

require_relative 'lib/legion/extensions/attention_economy/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-attention-economy'
  spec.version       = Legion::Extensions::AttentionEconomy::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Attention Economy'
  spec.description   = 'Models attention as a scarce resource for brain-modeled agentic AI; ' \
                       'allocates a limited attention budget across competing demands using economic principles'
  spec.homepage      = 'https://github.com/LegionIO/lex-attention-economy'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']        = spec.homepage
  spec.metadata['source_code_uri']     = 'https://github.com/LegionIO/lex-attention-economy'
  spec.metadata['documentation_uri']   = 'https://github.com/LegionIO/lex-attention-economy'
  spec.metadata['changelog_uri']       = 'https://github.com/LegionIO/lex-attention-economy'
  spec.metadata['bug_tracker_uri']     = 'https://github.com/LegionIO/lex-attention-economy/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,spec}/**/*') + %w[lex-attention-economy.gemspec Gemfile]
  end
  spec.require_paths = ['lib']
  spec.add_development_dependency 'legion-gaia'
end
