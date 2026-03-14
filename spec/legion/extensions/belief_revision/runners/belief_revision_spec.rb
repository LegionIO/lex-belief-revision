# frozen_string_literal: true

RSpec.describe Legion::Extensions::BeliefRevision::Runners::BeliefRevision do
  let(:runner) do
    obj = Object.new
    obj.extend(described_class)
    obj
  end

  describe '#add_belief' do
    it 'creates a belief' do
      result = runner.add_belief(proposition: 'test', domain: :general)
      expect(result[:success]).to be true
      expect(result[:belief_id]).to be_a(Symbol)
    end
  end

  describe '#submit_evidence' do
    it 'adds evidence to a belief' do
      created = runner.add_belief(proposition: 'sky is blue')
      result = runner.submit_evidence(
        belief_id: created[:belief_id], evidence_type: :observation,
        content: 'looked up', weight: 0.7
      )
      expect(result[:success]).to be true
      expect(result[:belief_credence]).to be > 0.5
    end

    it 'returns failure for unknown belief' do
      result = runner.submit_evidence(belief_id: :bogus, evidence_type: :observation, content: 'x')
      expect(result[:success]).to be false
    end
  end

  describe '#link_beliefs' do
    it 'links two beliefs' do
      a = runner.add_belief(proposition: 'A')
      b = runner.add_belief(proposition: 'B')
      result = runner.link_beliefs(from_id: a[:belief_id], to_id: b[:belief_id], link_type: :supports)
      expect(result[:success]).to be true
    end
  end

  describe '#revise_belief' do
    it 'revises credence' do
      created = runner.add_belief(proposition: 'test')
      result = runner.revise_belief(belief_id: created[:belief_id], new_credence: 0.9)
      expect(result[:success]).to be true
      expect(result[:credence]).to be_within(0.01).of(0.9)
    end

    it 'returns failure for unknown belief' do
      result = runner.revise_belief(belief_id: :bogus, new_credence: 0.5)
      expect(result[:success]).to be false
    end
  end

  describe '#belief_status' do
    it 'returns belief details' do
      created = runner.add_belief(proposition: 'test', credence: 0.8)
      result = runner.belief_status(belief_id: created[:belief_id])
      expect(result[:success]).to be true
      expect(result[:proposition]).to eq('test')
    end
  end

  describe '#find_contradictions' do
    it 'returns contradictions' do
      result = runner.find_contradictions
      expect(result[:success]).to be true
      expect(result[:count]).to eq(0)
    end
  end

  describe '#beliefs_in_domain' do
    it 'filters by domain' do
      runner.add_belief(proposition: 'A', domain: :ethics)
      runner.add_belief(proposition: 'B', domain: :science)
      result = runner.beliefs_in_domain(domain: :ethics)
      expect(result[:count]).to eq(1)
    end
  end

  describe '#coherence_report' do
    it 'returns coherence info' do
      result = runner.coherence_report
      expect(result[:success]).to be true
      expect(result).to include(:coherence, :believed, :disbelieved)
    end
  end

  describe '#update_belief_revision' do
    it 'ticks and returns stats' do
      result = runner.update_belief_revision
      expect(result[:success]).to be true
      expect(result).to include(:belief_count)
    end
  end

  describe '#belief_revision_stats' do
    it 'returns stats' do
      result = runner.belief_revision_stats
      expect(result[:success]).to be true
    end
  end
end
