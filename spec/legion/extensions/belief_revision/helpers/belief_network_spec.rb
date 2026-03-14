# frozen_string_literal: true

RSpec.describe Legion::Extensions::BeliefRevision::Helpers::BeliefNetwork do
  subject(:net) { described_class.new }

  describe '#add_belief' do
    it 'creates a belief' do
      belief = net.add_belief(proposition: 'water is wet')
      expect(belief).to be_a(Legion::Extensions::BeliefRevision::Helpers::Belief)
      expect(belief.proposition).to eq('water is wet')
    end

    it 'enforces MAX_BELIEFS' do
      200.times { |i| net.add_belief(proposition: "p_#{i}") }
      expect(net.add_belief(proposition: 'overflow')).to be_nil
    end
  end

  describe '#add_evidence' do
    it 'adds supporting evidence to a belief' do
      belief = net.add_belief(proposition: 'rain today', credence: 0.5)
      original = belief.credence
      net.add_evidence(belief_id: belief.id, evidence_type: :observation, content: 'dark clouds', weight: 0.7)
      expect(belief.credence).to be > original
    end

    it 'adds opposing evidence' do
      belief = net.add_belief(proposition: 'sunny day', credence: 0.7)
      original = belief.credence
      net.add_evidence(belief_id: belief.id, evidence_type: :observation, content: 'clouds', direction: :oppose,
                       weight: 0.6)
      expect(belief.credence).to be < original
    end

    it 'returns nil for unknown belief' do
      expect(net.add_evidence(belief_id: :bogus, evidence_type: :observation, content: 'x')).to be_nil
    end

    it 'records event in history' do
      belief = net.add_belief(proposition: 'test')
      net.add_evidence(belief_id: belief.id, evidence_type: :testimony, content: 'source said so')
      expect(net.history.size).to eq(1)
    end
  end

  describe '#link_beliefs' do
    it 'creates a link' do
      a = net.add_belief(proposition: 'A')
      b = net.add_belief(proposition: 'B')
      result = net.link_beliefs(from_id: a.id, to_id: b.id, link_type: :supports)
      expect(result).to include(from: a.id, to: b.id)
    end

    it 'rejects invalid link type' do
      a = net.add_belief(proposition: 'A')
      b = net.add_belief(proposition: 'B')
      expect(net.link_beliefs(from_id: a.id, to_id: b.id, link_type: :bogus)).to be_nil
    end

    it 'rejects unknown beliefs' do
      expect(net.link_beliefs(from_id: :x, to_id: :y, link_type: :supports)).to be_nil
    end
  end

  describe 'evidence propagation' do
    it 'propagates supporting evidence through supports link' do
      a = net.add_belief(proposition: 'A', credence: 0.5)
      b = net.add_belief(proposition: 'B', credence: 0.5)
      net.link_beliefs(from_id: a.id, to_id: b.id, link_type: :supports)

      original_b = b.credence
      net.add_evidence(belief_id: a.id, evidence_type: :observation, content: 'evidence for A', weight: 0.8)
      expect(b.credence).to be > original_b
    end

    it 'propagates opposing evidence through undermines link' do
      a = net.add_belief(proposition: 'A', credence: 0.5)
      b = net.add_belief(proposition: 'B', credence: 0.5)
      net.link_beliefs(from_id: a.id, to_id: b.id, link_type: :undermines)

      original_b = b.credence
      net.add_evidence(belief_id: a.id, evidence_type: :observation, content: 'evidence for A', weight: 0.8)
      expect(b.credence).to be < original_b
    end
  end

  describe '#revise_belief' do
    it 'revises credence' do
      belief = net.add_belief(proposition: 'test', credence: 0.5)
      net.revise_belief(belief_id: belief.id, new_credence: 0.9)
      expect(belief.credence).to eq(0.9)
    end

    it 'returns nil for unknown belief' do
      expect(net.revise_belief(belief_id: :bogus, new_credence: 0.5)).to be_nil
    end
  end

  describe '#contradictions' do
    it 'finds contradictions among linked beliefs' do
      a = net.add_belief(proposition: 'X is true', credence: 0.9)
      b = net.add_belief(proposition: 'X is false', credence: 0.1)
      net.link_beliefs(from_id: a.id, to_id: b.id, link_type: :undermines)
      expect(net.contradictions.size).to eq(1)
    end

    it 'ignores unlinked contradictory beliefs' do
      net.add_belief(proposition: 'X is true', credence: 0.9)
      net.add_belief(proposition: 'X is false', credence: 0.1)
      expect(net.contradictions).to be_empty
    end
  end

  describe '#beliefs_in' do
    it 'filters by domain' do
      net.add_belief(proposition: 'A', domain: :science)
      net.add_belief(proposition: 'B', domain: :ethics)
      expect(net.beliefs_in(domain: :science).size).to eq(1)
    end
  end

  describe '#believed and #disbelieved' do
    it 'separates believed and disbelieved' do
      net.add_belief(proposition: 'high', credence: 0.8)
      net.add_belief(proposition: 'low', credence: 0.1)
      expect(net.believed.size).to eq(1)
      expect(net.disbelieved.size).to eq(1)
    end
  end

  describe '#supported_beliefs' do
    it 'returns beliefs supported by given belief' do
      a = net.add_belief(proposition: 'A')
      b = net.add_belief(proposition: 'B')
      net.link_beliefs(from_id: a.id, to_id: b.id, link_type: :supports)
      expect(net.supported_beliefs(belief_id: a.id).size).to eq(1)
    end
  end

  describe '#undermining_beliefs' do
    it 'returns beliefs undermining given belief' do
      a = net.add_belief(proposition: 'A')
      b = net.add_belief(proposition: 'B')
      net.link_beliefs(from_id: a.id, to_id: b.id, link_type: :undermines)
      expect(net.undermining_beliefs(belief_id: b.id).size).to eq(1)
    end
  end

  describe '#decay_all' do
    it 'decays non-protected beliefs toward default' do
      belief = net.add_belief(proposition: 'test', credence: 0.9)
      original = belief.credence
      net.decay_all
      expect(belief.credence).to be < original
    end
  end

  describe '#coherence_score' do
    it 'returns 1.0 with no links' do
      expect(net.coherence_score).to eq(1.0)
    end

    it 'returns high coherence for consistent network' do
      a = net.add_belief(proposition: 'A', credence: 0.8)
      b = net.add_belief(proposition: 'B', credence: 0.8)
      net.link_beliefs(from_id: a.id, to_id: b.id, link_type: :supports)
      expect(net.coherence_score).to eq(1.0)
    end
  end

  describe '#to_h' do
    it 'returns expected keys' do
      expect(net.to_h).to include(:belief_count, :link_count, :coherence, :contradiction_count)
    end
  end
end
