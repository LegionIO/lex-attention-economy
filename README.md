# lex-attention-economy

Models attention as a scarce resource for brain-modeled agentic AI; allocates a limited attention budget across competing demands using economic principles.

## What It Does

Treats cognitive attention as a finite budget (default 1.0) that must be rationed across competing demands. Demands have a priority, a cost, and a return-on-investment score. The agent allocates budget to high-priority, high-ROI demands and can rebalance when over-committed. Budget recovers gradually over time. This models the well-documented human limitation that sustained cognitive engagement depletes attention resources.

## Core Concept: Attention Budget

```ruby
# Budget starts at 1.0, demands consume it
add_demand(label: :security_audit, demand_type: :cognitive, priority: 0.9, cost: 0.3, roi: 0.8)
add_demand(label: :log_monitoring, demand_type: :maintenance, priority: 0.3, cost: 0.1, roi: 0.4)

# Allocate budget to demands
allocate_demand(demand_id: security_audit_id)  # spends 0.3
allocate_demand(demand_id: log_monitoring_id)  # spends 0.1
# remaining budget: 0.6

# Recover some budget (e.g., after a rest period)
recover_budget  # adds 0.05
```

## Usage

```ruby
client = Legion::Extensions::AttentionEconomy::Client.new

# See where attention should go
client.best_roi_demands(limit: 3)
# => { demands: [{ label: :security_audit, roi: 0.8, priority: 0.9 }], count: 1 }

# Free up budget by dropping low-ROI allocations
client.rebalance_budget

# Check utilization
client.attention_status
# => { budget: 0.9, spent: 0.4, remaining: 0.5, utilization: 0.44 }
```

## Integration

Combine with lex-attention's signal filtering: filtered signals generate demands, and budget allocation determines which signals receive full cognitive processing. Wire into lex-tick to model the finite cognitive resources available per processing cycle.

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
