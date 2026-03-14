# lex-belief-revision

**Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Belief network engine for LegionIO — Bayesian updating, evidence weighting, and principled belief change. Models qualitative belief networks where beliefs have credence scores, link to other beliefs via support/undermine/entail/independent relationships, and transition through states (tentative → held → entrenched → protected) based on entrenchment thresholds.

## Gem Info

- **Gem name**: `lex-belief-revision`
- **Version**: `0.1.0`
- **Module**: `Legion::Extensions::BeliefRevision`
- **Ruby**: `>= 3.4`
- **License**: MIT

## File Structure

```
lib/legion/extensions/belief_revision/
  (no top-level module file)
  version.rb                      # VERSION = '0.1.0'
  client.rb                       # Client wrapper
  helpers/
    constants.rb                  # Limits, credence bounds, evidence types, link types, state thresholds
    belief.rb                     # Belief value object (credence, state, links, evidence)
    evidence.rb                   # Evidence value object
    belief_network.rb             # BeliefNetwork — credence updates, link propagation, coherence
  runners/
    belief_revision.rb            # Runner module with 9 public methods
spec/
  (spec files)
```

## Key Constants

```ruby
MAX_BELIEFS              = 200
MAX_EVIDENCE_PER_BELIEF  = 50
MAX_LINKS                = 500
MAX_HISTORY              = 300
DEFAULT_CREDENCE         = 0.5
CREDENCE_FLOOR           = 0.01
CREDENCE_CEILING         = 0.99
ENTRENCHMENT_ALPHA       = 0.05   # EMA alpha for entrenchment accumulation
EVIDENCE_WEIGHT          = 0.15   # default evidence impact on credence
DECAY_RATE               = 0.005
CONTRADICTION_THRESHOLD  = 0.3    # credence distance to flag contradiction

EVIDENCE_TYPES = %i[observation testimony inference analogy authority memory simulation]
LINK_TYPES     = %i[supports undermines entails independent]
BELIEF_STATES  = %i[tentative held entrenched protected]

STATE_THRESHOLDS = { entrenched: 0.85, held: 0.6, tentative: 0.3 }
CREDENCE_LABELS  = { (0.9..) => :near_certain, ... (..0.1) => :disbelieved }
```

## Runners

### `Runners::BeliefRevision`

Includes `Helpers::Constants` directly. All methods delegate to a private `@network` (`Helpers::BeliefNetwork` instance).

- `add_belief(proposition:, domain: :general, credence: DEFAULT_CREDENCE)` — add a belief with initial credence
- `submit_evidence(belief_id:, evidence_type:, content:, direction: :support, weight: EVIDENCE_WEIGHT, source: :unknown)` — add evidence affecting a belief's credence; direction `:support` increases credence, anything else decreases
- `link_beliefs(from_id:, to_id:, link_type:)` — create a directional relationship between two beliefs
- `revise_belief(belief_id:, new_credence:)` — directly set a belief's credence; triggers state transition
- `belief_status(belief_id:)` — full belief hash including state, credence, evidence count, links
- `find_contradictions` — pairs of linked beliefs with incompatible credence scores
- `beliefs_in_domain(domain:)` — all beliefs in a domain
- `coherence_report` — overall network coherence: believed/disbelieved/entrenched counts, contradiction count, coherence score
- `update_belief_revision` — decay all credences (slow regression)
- `belief_revision_stats` — stats hash

## Helpers

### `Helpers::BeliefNetwork`
Core engine. Manages `@beliefs`, `@links`, `@evidence` hashes. `coherence_score` measures how internally consistent the network is (percentage of linked pairs where the link type is consistent with relative credence scores). `contradictions` finds pairs where two `:supports`-linked beliefs have highly divergent credences, or `:undermines`-linked beliefs have similar credences.

### `Helpers::Belief`
Value object with state machine. State transitions based on `STATE_THRESHOLDS`: tentative (< 0.3), held (0.3–0.6), entrenched (0.6–0.85), protected (> 0.85). `:protected` beliefs resist revision.

### `Helpers::Evidence`
Value object: belief_id, evidence_type, content, direction, weight, source, created_at.

## Integration Points

Pairs with lex-bayesian-belief for the complete belief stack: Bayesian handles probabilistic updates; belief-revision handles network topology and qualitative entrenchment. `find_contradictions` feeds into lex-dream's contradiction_resolution phase. Entrenched/protected beliefs can gate lex-conflict's willingness to accept resolution proposals. `coherence_report` informs governance about the agent's epistemic consistency.

## Development Notes

- Note: no top-level module file — namespace is defined via individual files; `BeliefRevision` module established by version.rb
- Runner uses direct `include Helpers::Constants` (not guarded)
- `revise_belief` applies `:protected` state resistance — protected beliefs have limited revision (implementation detail to verify in engine)
- `CONTRADICTION_THRESHOLD = 0.3` means beliefs with credence distances > 0.3 linked by `:supports` are flagged as contradictions
