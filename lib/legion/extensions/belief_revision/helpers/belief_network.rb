# frozen_string_literal: true

module Legion
  module Extensions
    module BeliefRevision
      module Helpers
        class BeliefNetwork
          include Constants

          attr_reader :beliefs, :links, :history

          def initialize
            @beliefs  = {}
            @links    = []
            @counter  = 0
            @ev_count = 0
            @history  = []
          end

          def add_belief(proposition:, domain: :general, credence: DEFAULT_CREDENCE)
            return nil if @beliefs.size >= MAX_BELIEFS

            @counter += 1
            belief_id = :"belief_#{@counter}"
            belief = Belief.new(id: belief_id, proposition: proposition, domain: domain, credence: credence)
            @beliefs[belief_id] = belief
            belief
          end

          def add_evidence(belief_id:, evidence_type:, content:, direction: :support, weight: EVIDENCE_WEIGHT,
                           source: :unknown)
            belief = @beliefs[belief_id]
            return nil unless belief

            @ev_count += 1
            ev = Evidence.new(id: :"ev_#{@ev_count}", evidence_type: evidence_type,
                              content: content, weight: weight, source: source)
            result = direction == :support ? belief.add_supporting_evidence(ev) : belief.add_opposing_evidence(ev)
            propagate_evidence(belief_id, direction) if result
            record_event(:evidence, belief_id: belief_id, direction: direction)
            result
          end

          def link_beliefs(from_id:, to_id:, link_type:)
            return nil unless @beliefs.key?(from_id) && @beliefs.key?(to_id)
            return nil unless LINK_TYPES.include?(link_type)
            return nil if @links.size >= MAX_LINKS

            link = { from: from_id, to: to_id, type: link_type }
            @links << link
            link
          end

          def revise_belief(belief_id:, new_credence:)
            belief = @beliefs[belief_id]
            return nil unless belief

            belief.revise(new_credence: new_credence)
            record_event(:revision, belief_id: belief_id, new_credence: new_credence)
            belief
          end

          def contradictions
            pairs = []
            ids = @beliefs.keys
            ids.combination(2) do |a, b|
              pairs << [a, b] if @beliefs[a].contradicts?(@beliefs[b]) && linked?(a, b)
            end
            pairs
          end

          def beliefs_in(domain:)
            @beliefs.values.select { |b| b.domain == domain }.map(&:to_h)
          end

          def believed
            @beliefs.values.select(&:believed?).map(&:to_h)
          end

          def disbelieved
            @beliefs.values.select(&:disbelieved?).map(&:to_h)
          end

          def entrenched
            @beliefs.values.select { |b| b.state == :entrenched }.map(&:to_h)
          end

          def supported_beliefs(belief_id:)
            linked_ids = @links.select { |l| l[:from] == belief_id && l[:type] == :supports }.map { |l| l[:to] }
            linked_ids.filter_map { |id| @beliefs[id]&.to_h }
          end

          def undermining_beliefs(belief_id:)
            linked_ids = @links.select { |l| l[:to] == belief_id && l[:type] == :undermines }.map { |l| l[:from] }
            linked_ids.filter_map { |id| @beliefs[id]&.to_h }
          end

          def decay_all
            @beliefs.each_value(&:decay)
          end

          def coherence_score
            return 1.0 if @links.empty?

            coherent = @links.count { |l| link_coherent?(l) }
            coherent.to_f / @links.size
          end

          def to_h
            {
              belief_count:        @beliefs.size,
              link_count:          @links.size,
              believed_count:      @beliefs.values.count(&:believed?),
              disbelieved_count:   @beliefs.values.count(&:disbelieved?),
              entrenched_count:    @beliefs.values.count { |b| b.state == :entrenched },
              contradiction_count: contradictions.size,
              coherence:           coherence_score.round(4),
              history_size:        @history.size
            }
          end

          PROPAGATION_SIGNS = {
            %i[supports support]   => 1,
            %i[supports oppose]    => -1,
            %i[undermines support] => -1,
            %i[undermines oppose]  => 1
          }.freeze

          private

          def propagate_evidence(belief_id, direction)
            @links.each do |link|
              next unless link[:from] == belief_id

              target = @beliefs[link[:to]]
              next unless target

              apply_propagation(target, link[:type], direction)
            end
          end

          def apply_propagation(target, link_type, direction)
            return if target.protected?

            shift = propagation_shift(link_type, direction)
            return if shift.zero?

            target.revise(new_credence: target.credence + shift)
          end

          def propagation_shift(link_type, direction)
            sign = PROPAGATION_SIGNS.fetch([link_type, direction], 0)
            EVIDENCE_WEIGHT * 0.5 * sign
          end

          def linked?(id_a, id_b)
            @links.any? do |l|
              (l[:from] == id_a && l[:to] == id_b) || (l[:from] == id_b && l[:to] == id_a)
            end
          end

          def link_coherent?(link)
            from = @beliefs[link[:from]]
            to = @beliefs[link[:to]]
            return true unless from && to

            check_link_coherence(from, to, link[:type])
          end

          def check_link_coherence(from, to, type)
            return support_coherent?(from, to) if type == :supports
            return from.believed? != to.believed? if type == :undermines

            true
          end

          def support_coherent?(from, to)
            from.believed? == to.believed?
          end

          def record_event(type, **details)
            @history << { type: type, at: Time.now.utc }.merge(details)
            @history.shift while @history.size > MAX_HISTORY
          end
        end
      end
    end
  end
end
