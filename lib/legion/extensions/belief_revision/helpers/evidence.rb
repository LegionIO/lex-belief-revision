# frozen_string_literal: true

module Legion
  module Extensions
    module BeliefRevision
      module Helpers
        class Evidence
          include Constants

          attr_reader :id, :evidence_type, :content, :weight, :source, :created_at

          def initialize(id:, evidence_type:, content:, weight: EVIDENCE_WEIGHT, source: :unknown)
            raise ArgumentError, "invalid type: #{evidence_type}" unless EVIDENCE_TYPES.include?(evidence_type)

            @id            = id
            @evidence_type = evidence_type
            @content       = content
            @weight        = weight.to_f.clamp(0.0, 1.0)
            @source        = source
            @created_at    = Time.now.utc
          end

          def strong?
            @weight >= 0.5
          end

          def weak?
            @weight < 0.2
          end

          def to_h
            {
              id:            @id,
              evidence_type: @evidence_type,
              content:       @content,
              weight:        @weight.round(4),
              source:        @source,
              created_at:    @created_at
            }
          end
        end
      end
    end
  end
end
