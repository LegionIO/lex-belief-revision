# frozen_string_literal: true

module Legion
  module Extensions
    module BeliefRevision
      module Helpers
        module Constants
          MAX_BELIEFS = 200
          MAX_EVIDENCE_PER_BELIEF = 50
          MAX_LINKS = 500
          MAX_HISTORY = 300

          DEFAULT_CREDENCE = 0.5
          CREDENCE_FLOOR = 0.01
          CREDENCE_CEILING = 0.99
          ENTRENCHMENT_ALPHA = 0.05
          EVIDENCE_WEIGHT = 0.15
          DECAY_RATE = 0.005
          CONTRADICTION_THRESHOLD = 0.3

          EVIDENCE_TYPES = %i[
            observation testimony inference analogy
            authority memory simulation
          ].freeze

          LINK_TYPES = %i[supports undermines entails independent].freeze

          BELIEF_STATES = %i[
            tentative held entrenched protected
          ].freeze

          CREDENCE_LABELS = {
            (0.9..)     => :near_certain,
            (0.7...0.9) => :confident,
            (0.5...0.7) => :leaning,
            (0.3...0.5) => :uncertain,
            (0.1...0.3) => :doubtful,
            (..0.1)     => :disbelieved
          }.freeze

          STATE_THRESHOLDS = {
            entrenched: 0.85,
            held:       0.6,
            tentative:  0.3
          }.freeze
        end
      end
    end
  end
end
