# frozen_string_literal: true

RSpec.describe Legion::Extensions::BeliefRevision::Helpers::Belief do
  subject(:belief) do
    described_class.new(id: :b_one, proposition: 'the earth is round', domain: :science, credence: 0.8)
  end

  describe '#initialize' do
    it 'sets id, proposition, domain' do
      expect(belief.id).to eq(:b_one)
      expect(belief.proposition).to eq('the earth is round')
      expect(belief.domain).to eq(:science)
    end

    it 'sets credence' do
      expect(belief.credence).to eq(0.8)
    end

    it 'starts with empty evidence' do
      expect(belief.evidence_for).to be_empty
      expect(belief.evidence_against).to be_empty
    end

    it 'clamps credence to floor/ceiling' do
      b = described_class.new(id: :x, proposition: 'x', credence: 2.0)
      expect(b.credence).to eq(0.99)
    end
  end

  describe '#add_supporting_evidence' do
    it 'increases credence' do
      ev = Legion::Extensions::BeliefRevision::Helpers::Evidence.new(
        id: :ev, evidence_type: :observation, content: 'photo from space', weight: 0.8
      )
      original = belief.credence
      belief.add_supporting_evidence(ev)
      expect(belief.credence).to be > original
    end

    it 'adds to evidence_for' do
      ev = Legion::Extensions::BeliefRevision::Helpers::Evidence.new(
        id: :ev, evidence_type: :testimony, content: 'astronaut said so', weight: 0.5
      )
      belief.add_supporting_evidence(ev)
      expect(belief.evidence_for.size).to eq(1)
    end
  end

  describe '#add_opposing_evidence' do
    it 'decreases credence' do
      ev = Legion::Extensions::BeliefRevision::Helpers::Evidence.new(
        id: :ev, evidence_type: :testimony, content: 'flat earth claim', weight: 0.6
      )
      original = belief.credence
      belief.add_opposing_evidence(ev)
      expect(belief.credence).to be < original
    end
  end

  describe '#revise' do
    it 'sets new credence and increments revision count' do
      belief.revise(new_credence: 0.3)
      expect(belief.credence).to eq(0.3)
      expect(belief.revision_count).to eq(1)
    end
  end

  describe '#protect! and #unprotect!' do
    it 'protects and unprotects' do
      belief.protect!
      expect(belief.protected?).to be true
      belief.unprotect!
      expect(belief.protected?).to be false
    end
  end

  describe '#state' do
    it 'returns :tentative for low credence' do
      b = described_class.new(id: :x, proposition: 'x', credence: 0.2)
      expect(b.state).to eq(:tentative)
    end

    it 'returns :held for moderate credence' do
      expect(belief.state).to eq(:held)
    end

    it 'returns :protected when protected' do
      belief.protect!
      expect(belief.state).to eq(:protected)
    end
  end

  describe '#credence_label' do
    it 'returns a symbol' do
      expect(belief.credence_label).to be_a(Symbol)
    end

    it 'returns :confident for 0.8' do
      expect(belief.credence_label).to eq(:confident)
    end
  end

  describe '#believed? and #disbelieved?' do
    it 'believed at 0.8' do
      expect(belief.believed?).to be true
      expect(belief.disbelieved?).to be false
    end

    it 'disbelieved at low credence' do
      b = described_class.new(id: :x, proposition: 'x', credence: 0.1)
      expect(b.disbelieved?).to be true
    end
  end

  describe '#contradicts?' do
    it 'detects contradiction between believed and disbelieved' do
      low = described_class.new(id: :y, proposition: 'opposite', credence: 0.1)
      expect(belief.contradicts?(low)).to be true
    end

    it 'no contradiction between two believed' do
      high = described_class.new(id: :y, proposition: 'also true', credence: 0.8)
      expect(belief.contradicts?(high)).to be false
    end
  end

  describe '#evidence_ratio' do
    it 'returns 0.5 with no evidence' do
      expect(belief.evidence_ratio).to eq(0.5)
    end
  end

  describe '#decay' do
    it 'moves credence toward default' do
      original = belief.credence
      belief.decay
      expect(belief.credence).to be < original
    end

    it 'does not decay protected beliefs' do
      belief.protect!
      original = belief.credence
      belief.decay
      expect(belief.credence).to eq(original)
    end
  end

  describe '#to_h' do
    it 'returns expected keys' do
      expect(belief.to_h).to include(:id, :proposition, :credence, :state, :entrenchment)
    end
  end
end
