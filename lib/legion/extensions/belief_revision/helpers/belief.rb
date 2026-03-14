# frozen_string_literal: true

module Legion
  module Extensions
    module BeliefRevision
      module Helpers
        class Belief
          include Constants

          attr_reader :id, :proposition, :domain, :credence, :evidence_for, :evidence_against, :entrenchment,
                      :created_at, :updated_at, :revision_count

          def initialize(id:, proposition:, domain: :general, credence: DEFAULT_CREDENCE)
            @id               = id
            @proposition      = proposition
            @domain           = domain
            @credence         = credence.to_f.clamp(CREDENCE_FLOOR, CREDENCE_CEILING)
            @evidence_for     = []
            @evidence_against = []
            @entrenchment     = 0.0
            @revision_count   = 0
            @created_at       = Time.now.utc
            @updated_at       = @created_at
            @protected        = false
          end

          def add_supporting_evidence(evidence)
            return nil if @evidence_for.size >= MAX_EVIDENCE_PER_BELIEF

            @evidence_for << evidence
            update_credence_from_evidence(evidence, :support)
            evidence
          end

          def add_opposing_evidence(evidence)
            return nil if @evidence_against.size >= MAX_EVIDENCE_PER_BELIEF

            @evidence_against << evidence
            update_credence_from_evidence(evidence, :oppose)
            evidence
          end

          def revise(new_credence:)
            @credence = new_credence.to_f.clamp(CREDENCE_FLOOR, CREDENCE_CEILING)
            @revision_count += 1
            @updated_at = Time.now.utc
            deepen_entrenchment
          end

          def protect!
            @protected = true
          end

          def unprotect!
            @protected = false
          end

          def protected?
            @protected
          end

          def state
            return :protected if @protected
            return :entrenched if @entrenchment >= STATE_THRESHOLDS[:entrenched]
            return :held if @credence >= STATE_THRESHOLDS[:held]

            :tentative
          end

          def credence_label
            CREDENCE_LABELS.each { |range, lbl| return lbl if range.cover?(@credence) }
            :disbelieved
          end

          def believed?
            @credence >= 0.5
          end

          def disbelieved?
            @credence < 0.3
          end

          def contradicts?(other)
            (believed? && other.disbelieved?) || (disbelieved? && other.believed?)
          end

          def evidence_ratio
            total = @evidence_for.size + @evidence_against.size
            return 0.5 if total.zero?

            @evidence_for.size.to_f / total
          end

          def total_evidence_count
            @evidence_for.size + @evidence_against.size
          end

          def decay
            return if @protected
            return if @entrenchment >= STATE_THRESHOLDS[:entrenched]

            @credence = approach_default(@credence)
          end

          def to_h
            {
              id:               @id,
              proposition:      @proposition,
              domain:           @domain,
              credence:         @credence.round(4),
              credence_label:   credence_label,
              state:            state,
              evidence_for:     @evidence_for.size,
              evidence_against: @evidence_against.size,
              entrenchment:     @entrenchment.round(4),
              revision_count:   @revision_count,
              protected:        @protected
            }
          end

          private

          def update_credence_from_evidence(evidence, direction)
            return if @protected

            adjustment = evidence.weight * EVIDENCE_WEIGHT
            resistance = @entrenchment * 0.5
            effective = adjustment * (1.0 - resistance)

            @credence = if direction == :support
                          [@credence + effective, CREDENCE_CEILING].min
                        else
                          [@credence - effective, CREDENCE_FLOOR].max
                        end
            @updated_at = Time.now.utc
            deepen_entrenchment
          end

          def deepen_entrenchment
            @entrenchment = [@entrenchment + ENTRENCHMENT_ALPHA, 1.0].min
          end

          def approach_default(value)
            diff = DEFAULT_CREDENCE - value
            value + (diff * DECAY_RATE)
          end
        end
      end
    end
  end
end
