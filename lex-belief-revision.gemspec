# frozen_string_literal: true

require_relative 'lib/legion/extensions/belief_revision/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-belief-revision'
  spec.version       = Legion::Extensions::BeliefRevision::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'Bayesian belief revision for LegionIO'
  spec.description   = 'Belief network engine for LegionIO — ' \
                       'Bayesian updating, evidence weighting, and principled belief change'
  spec.homepage      = 'https://github.com/LegionIO/lex-belief-revision'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']      = spec.homepage
  spec.metadata['source_code_uri']   = spec.homepage
  spec.metadata['documentation_uri'] = "#{spec.homepage}/blob/master/README.md"
  spec.metadata['changelog_uri']     = "#{spec.homepage}/blob/master/CHANGELOG.md"
  spec.metadata['bug_tracker_uri']   = "#{spec.homepage}/issues"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files         = Dir['lib/**/*']
  spec.require_paths = ['lib']
end
