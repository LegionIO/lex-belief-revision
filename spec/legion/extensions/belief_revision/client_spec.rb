# frozen_string_literal: true

RSpec.describe Legion::Extensions::BeliefRevision::Client do
  subject(:client) { described_class.new }

  it 'full lifecycle: add, evidence, link, check contradictions' do
    a = client.add_belief(proposition: 'it will rain', credence: 0.6)
    expect(a[:success]).to be true

    b = client.add_belief(proposition: 'it will be sunny', credence: 0.7)
    client.link_beliefs(from_id: a[:belief_id], to_id: b[:belief_id], link_type: :undermines)

    client.submit_evidence(
      belief_id: a[:belief_id], evidence_type: :observation,
      content: 'dark clouds', weight: 0.8
    )

    status = client.belief_status(belief_id: a[:belief_id])
    expect(status[:credence]).to be > 0.6

    report = client.coherence_report
    expect(report[:coherence]).to be_a(Float)
  end

  it 'accepts injected network' do
    network = Legion::Extensions::BeliefRevision::Helpers::BeliefNetwork.new
    c = described_class.new(network: network)
    c.add_belief(proposition: 'test')
    expect(network.beliefs.size).to eq(1)
  end
end
