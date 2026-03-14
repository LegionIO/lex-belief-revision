# frozen_string_literal: true

RSpec.describe Legion::Extensions::BeliefRevision::Helpers::Evidence do
  subject(:evidence) do
    described_class.new(id: :ev_one, evidence_type: :observation, content: 'sky is blue', weight: 0.6)
  end

  describe '#initialize' do
    it 'sets id and type' do
      expect(evidence.id).to eq(:ev_one)
      expect(evidence.evidence_type).to eq(:observation)
    end

    it 'sets content and weight' do
      expect(evidence.content).to eq('sky is blue')
      expect(evidence.weight).to eq(0.6)
    end

    it 'defaults source to :unknown' do
      expect(evidence.source).to eq(:unknown)
    end

    it 'rejects invalid type' do
      expect { described_class.new(id: :x, evidence_type: :bogus, content: 'x') }.to raise_error(ArgumentError)
    end

    it 'clamps weight' do
      ev = described_class.new(id: :x, evidence_type: :testimony, content: 'x', weight: 5.0)
      expect(ev.weight).to eq(1.0)
    end
  end

  describe '#strong?' do
    it 'returns true for weight >= 0.5' do
      expect(evidence.strong?).to be true
    end
  end

  describe '#weak?' do
    it 'returns true for low weight' do
      ev = described_class.new(id: :x, evidence_type: :analogy, content: 'x', weight: 0.1)
      expect(ev.weak?).to be true
    end
  end

  describe '#to_h' do
    it 'returns expected keys' do
      expect(evidence.to_h).to include(:id, :evidence_type, :content, :weight, :source)
    end
  end
end
