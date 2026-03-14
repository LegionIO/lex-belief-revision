# lex-belief-revision

Bayesian belief revision for LegionIO — belief networks with evidence weighting, state entrenchment, and coherence monitoring.

## What It Does

Manages qualitative belief networks where beliefs are connected by logical relationships (supports/undermines/entails) and have credence scores that update with evidence. Beliefs transition through states: `tentative` → `held` → `entrenched` → `protected`, with protected beliefs resisting revision. Contradictions in the network are detected and can be fed to the dream cycle for resolution.

## Core Concept: Belief States and Network Coherence

```ruby
# Beliefs transition based on credence thresholds:
# tentative: credence < 0.3
# held:       credence 0.3–0.6
# entrenched: credence 0.6–0.85
# protected:  credence > 0.85
```

## Usage

```ruby
client = Legion::Extensions::BeliefRevision::Client.new

# Add beliefs
b1 = client.add_belief(proposition: 'Vault is reliable', domain: :infrastructure)
b2 = client.add_belief(proposition: 'Consul is reliable', domain: :infrastructure)

# Link them (Vault reliability supports Consul reliability in our setup)
client.link_beliefs(from_id: b1[:belief_id], to_id: b2[:belief_id], link_type: :supports)

# Submit evidence
client.submit_evidence(
  belief_id: b1[:belief_id],
  evidence_type: :observation,
  content: '99.99% uptime over 6 months',
  direction: :support,
  weight: 0.2
)

# Check for contradictions
client.find_contradictions
# => { contradictions: [], count: 0 }

# Network coherence
client.coherence_report
# => { coherence: 0.87, believed: 2, entrenched: 1, contradictions: 0 }
```

## Integration

Pairs with lex-bayesian-belief for the full belief management stack. `find_contradictions` feeds into lex-dream's contradiction_resolution phase. Entrenched beliefs signal high-confidence knowledge that should be treated as stable foundations for reasoning.

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
