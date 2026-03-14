# frozen_string_literal: true

module Legion
  module Extensions
    module BeliefRevision
      module Runners
        module BeliefRevision
          include Helpers::Constants
          include Legion::Extensions::Helpers::Lex if defined?(Legion::Extensions::Helpers::Lex)

          def add_belief(proposition:, domain: :general, credence: DEFAULT_CREDENCE, **)
            belief = network.add_belief(proposition: proposition, domain: domain, credence: credence)
            return { success: false, reason: :limit_reached } unless belief

            { success: true, belief_id: belief.id, credence: belief.credence.round(4) }
          end

          def submit_evidence(belief_id:, evidence_type:, content:, direction: :support,
                              weight: EVIDENCE_WEIGHT, source: :unknown, **)
            ev = network.add_evidence(
              belief_id: belief_id, evidence_type: evidence_type, content: content,
              direction: direction, weight: weight, source: source
            )
            return { success: false, reason: :not_found_or_full } unless ev

            belief = network.beliefs[belief_id]
            { success: true, evidence_id: ev.id, belief_credence: belief.credence.round(4) }
          end

          def link_beliefs(from_id:, to_id:, link_type:, **)
            result = network.link_beliefs(from_id: from_id, to_id: to_id, link_type: link_type)
            return { success: false, reason: :invalid_or_limit } unless result

            { success: true, from: from_id, to: to_id, link_type: link_type }
          end

          def revise_belief(belief_id:, new_credence:, **)
            belief = network.revise_belief(belief_id: belief_id, new_credence: new_credence)
            return { success: false, reason: :not_found } unless belief

            { success: true, belief_id: belief_id, credence: belief.credence.round(4), state: belief.state }
          end

          def belief_status(belief_id:, **)
            belief = network.beliefs[belief_id]
            return { success: false, reason: :not_found } unless belief

            { success: true }.merge(belief.to_h)
          end

          def find_contradictions(**)
            pairs = network.contradictions
            { success: true, contradictions: pairs, count: pairs.size }
          end

          def beliefs_in_domain(domain:, **)
            beliefs = network.beliefs_in(domain: domain)
            { success: true, beliefs: beliefs, count: beliefs.size }
          end

          def coherence_report(**)
            { success: true, coherence: network.coherence_score.round(4),
              believed: network.believed.size, disbelieved: network.disbelieved.size,
              entrenched: network.entrenched.size, contradictions: network.contradictions.size }
          end

          def update_belief_revision(**)
            network.decay_all
            { success: true }.merge(network.to_h)
          end

          def belief_revision_stats(**)
            { success: true }.merge(network.to_h)
          end

          private

          def network
            @network ||= Helpers::BeliefNetwork.new
          end
        end
      end
    end
  end
end
