# lex-attention-economy

**Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Models attention as a scarce resource for brain-modeled agentic AI; allocates a limited attention budget across competing demands using economic principles. The agent has a finite attention budget (default 1.0) that is spent on demands and recovers over time — forcing trade-offs between competing cognitive tasks.

## Gem Info

- **Gem name**: `lex-attention-economy`
- **Version**: `0.1.0`
- **Module**: `Legion::Extensions::AttentionEconomy`
- **Ruby**: `>= 3.4`
- **License**: MIT

## File Structure

```
lib/legion/extensions/attention_economy/
  attention_economy.rb        # Main extension module
  version.rb                  # VERSION = '0.1.0'
  client.rb                   # Client wrapper
  helpers/
    constants.rb              # Budget defaults, recovery rate, demand types, labels
    demand.rb                 # Demand value object (priority, cost, ROI)
    attention_budget.rb       # AttentionBudget — manages budget, allocations, rebalancing
  runners/
    attention_economy.rb      # Runner module with 9 public methods
spec/
  (spec files)
```

## Key Constants

```ruby
MAX_DEMANDS          = 200
DEFAULT_BUDGET       = 1.0
BUDGET_RECOVERY_RATE = 0.05    # per recover! call
MIN_ALLOCATION       = 0.01

PRIORITY_LABELS = {
  (0.8..) => :critical, (0.6...0.8) => :high, (0.4...0.6) => :moderate,
  (0.2...0.4) => :low, (..0.2) => :background
}
EFFICIENCY_LABELS = {
  (0.8..) => :excellent, ... (..0.2) => :wasted
}
DEMAND_TYPES = %i[task sensory social emotional cognitive maintenance]
```

## Runners

### `Runners::AttentionEconomy`

All methods delegate to a private `@attention_budget` (`Helpers::AttentionBudget` instance).

- `add_demand(label:, demand_type:, priority:, cost:, roi: 0.5)` — create a demand competing for budget; raises ArgumentError on invalid demand_type
- `allocate_demand(demand_id:, amount: nil)` — allocate budget to a demand; fails if insufficient remaining budget
- `deallocate_demand(demand_id:)` — free budget allocated to a demand
- `recover_budget(amount: nil)` — recover budget (default `BUDGET_RECOVERY_RATE`)
- `prioritized_demands` — demands sorted by priority descending
- `best_roi_demands(limit: 5)` — demands sorted by ROI descending
- `rebalance_budget` — deallocate low-ROI demands to free budget
- `attention_status` — budget report: total, spent, remaining, utilization, demand_count
- `attention_snapshot` — full state hash

## Helpers

### `Helpers::AttentionBudget`
Core engine. Tracks `@budget` (remaining), `@total` (1.0), and `@demands` hash. `allocate` deducts `demand.cost` from budget. `rebalance` identifies the lowest-ROI allocated demands and deallocates them. `budget_report` computes `utilization = spent / total`.

### `Helpers::Demand`
Value object: label, demand_type, priority, cost, roi, allocated (bool), allocated_amount.

## Integration Points

No actor defined. Complements lex-attention's signal filtering: after filtering signals, high-priority demands drive which cognitive phases receive attention budget. `rebalance_budget` is useful at the start of each tick to clear low-value allocations before new demands compete. Integrates with lex-tick by modeling the limited cognitive budget available per tick — high-cost tasks may not fit within the tick budget.

## Development Notes

- `add_demand` raises `ArgumentError` (not return hash) for invalid `demand_type` — callers must handle
- `recover_budget` has a default from the constant but can accept explicit amount — useful for simulating rest periods
- `rebalance` determines "low ROI" by sorting all allocated demands by ROI and deallocating the bottom half
- Budget recovery is additive (not reset to 1.0) — sustained high demand will gradually deplete the budget if recovery rate < spend rate
