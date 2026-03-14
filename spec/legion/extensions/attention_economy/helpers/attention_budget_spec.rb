# frozen_string_literal: true

require 'legion/extensions/attention_economy/helpers/attention_budget'

RSpec.describe Legion::Extensions::AttentionEconomy::Helpers::AttentionBudget do
  subject(:budget) { described_class.new }

  def add_demand(label: 'work', demand_type: :task, priority: 0.5, cost: 0.2, roi: 0.6)
    budget.create_demand(label: label, demand_type: demand_type, priority: priority, cost: cost, roi: roi)
  end

  describe '#initialize' do
    it 'starts with full available budget' do
      expect(budget.available_budget).to eq(1.0)
    end

    it 'starts with 0.0 spent' do
      expect(budget.spent).to eq(0.0)
    end

    it 'starts with 0.0 recovered' do
      expect(budget.recovered).to eq(0.0)
    end

    it 'accepts custom total_budget' do
      b = described_class.new(total_budget: 2.0)
      expect(b.total_budget).to eq(2.0)
    end
  end

  describe '#create_demand' do
    it 'returns a Demand object' do
      demand = add_demand
      expect(demand).to be_a(Legion::Extensions::AttentionEconomy::Helpers::Demand)
    end

    it 'raises ArgumentError for invalid demand_type' do
      expect { budget.create_demand(label: 'x', demand_type: :invalid, priority: 0.5, cost: 0.1) }
        .to raise_error(ArgumentError, /demand_type/)
    end

    it 'raises ArgumentError when max demands reached' do
      stub_const('Legion::Extensions::AttentionEconomy::Helpers::Constants::MAX_DEMANDS', 1)
      add_demand(label: 'first')
      expect { add_demand(label: 'second') }.to raise_error(ArgumentError, /max demands/)
    end
  end

  describe '#allocate' do
    it 'allocates demand at its cost' do
      demand = add_demand(cost: 0.3)
      result = budget.allocate(demand_id: demand.id)
      expect(result[:allocated]).to be true
      expect(result[:amount]).to eq(0.3)
    end

    it 'deducts from budget' do
      demand = add_demand(cost: 0.3)
      budget.allocate(demand_id: demand.id)
      expect(budget.available_budget).to be_within(0.001).of(0.7)
    end

    it 'allows explicit amount override' do
      demand = add_demand(cost: 0.3)
      result = budget.allocate(demand_id: demand.id, amount: 0.1)
      expect(result[:amount]).to eq(0.1)
    end

    it 'returns not_found for unknown demand_id' do
      result = budget.allocate(demand_id: 'nonexistent')
      expect(result[:allocated]).to be false
      expect(result[:reason]).to eq(:not_found)
    end

    it 'returns insufficient_budget when budget exhausted' do
      add_demand(cost: 0.9).tap { |d| budget.allocate(demand_id: d.id) }
      demand2 = add_demand(label: 'big', cost: 0.5)
      result = budget.allocate(demand_id: demand2.id)
      expect(result[:allocated]).to be false
      expect(result[:reason]).to eq(:insufficient_budget)
    end
  end

  describe '#deallocate' do
    it 'frees allocated amount' do
      demand = add_demand(cost: 0.4)
      budget.allocate(demand_id: demand.id)
      result = budget.deallocate(demand_id: demand.id)
      expect(result[:deallocated]).to be true
      expect(result[:freed]).to be_within(0.001).of(0.4)
      expect(budget.available_budget).to be_within(0.001).of(1.0)
    end

    it 'returns not_found for unknown demand_id' do
      result = budget.deallocate(demand_id: 'unknown')
      expect(result[:deallocated]).to be false
    end
  end

  describe '#recover!' do
    it 'restores budget by recovery rate' do
      demand = add_demand(cost: 0.3)
      budget.allocate(demand_id: demand.id)
      budget.recover!
      expect(budget.spent).to be_within(0.001).of(0.25)
    end

    it 'accepts custom amount' do
      demand = add_demand(cost: 0.5)
      budget.allocate(demand_id: demand.id)
      budget.recover!(amount: 0.2)
      expect(budget.spent).to be_within(0.001).of(0.3)
    end

    it 'does not go below 0 spent' do
      budget.recover!(amount: 0.5)
      expect(budget.spent).to eq(0.0)
    end

    it 'accumulates recovered total' do
      demand = add_demand(cost: 0.3)
      budget.allocate(demand_id: demand.id)
      budget.recover!
      expect(budget.recovered).to be > 0
    end
  end

  describe '#utilization' do
    it 'returns 0.0 when nothing spent' do
      expect(budget.utilization).to eq(0.0)
    end

    it 'returns proportion of budget spent' do
      demand = add_demand(cost: 0.5)
      budget.allocate(demand_id: demand.id)
      expect(budget.utilization).to be_within(0.001).of(0.5)
    end
  end

  describe '#prioritized_demands' do
    it 'returns demands sorted by priority descending' do
      budget.create_demand(label: 'low', demand_type: :task, priority: 0.2, cost: 0.1)
      budget.create_demand(label: 'high', demand_type: :task, priority: 0.9, cost: 0.1)
      budget.create_demand(label: 'mid', demand_type: :task, priority: 0.5, cost: 0.1)
      sorted = budget.prioritized_demands
      expect(sorted.first.priority).to be >= sorted.last.priority
    end
  end

  describe '#best_roi' do
    it 'returns top demands by efficiency' do
      budget.create_demand(label: 'poor', demand_type: :task, priority: 0.5, cost: 0.9, roi: 0.1)
      budget.create_demand(label: 'great', demand_type: :task, priority: 0.5, cost: 0.1, roi: 0.9)
      best = budget.best_roi(limit: 1)
      expect(best.first.label).to eq('great')
    end

    it 'respects limit parameter' do
      3.times { |i| budget.create_demand(label: "d#{i}", demand_type: :task, priority: 0.5, cost: 0.1, roi: 0.5) }
      expect(budget.best_roi(limit: 2).size).to eq(2)
    end
  end

  describe '#over_budget?' do
    it 'returns false when within budget' do
      expect(budget.over_budget?).to be false
    end
  end

  describe '#budget_pressure' do
    it 'equals utilization' do
      expect(budget.budget_pressure).to eq(budget.utilization)
    end
  end

  describe '#rebalance' do
    it 'returns rebalanced: 0 when not over budget' do
      result = budget.rebalance
      expect(result[:rebalanced]).to eq(0)
    end

    it 'frees lowest-priority demands when over budget' do
      b = described_class.new(total_budget: 0.5)
      d1 = b.create_demand(label: 'lo', demand_type: :task, priority: 0.1, cost: 0.3)
      d2 = b.create_demand(label: 'hi', demand_type: :task, priority: 0.9, cost: 0.3)
      b.allocate(demand_id: d1.id)
      b.allocate(demand_id: d2.id)
      b.instance_variable_set(:@spent, 0.7)
      result = b.rebalance
      expect(result[:rebalanced]).to be >= 1
    end
  end

  describe '#budget_report' do
    it 'includes all expected keys' do
      report = budget.budget_report
      %i[total_budget spent available utilization recovered over_budget budget_pressure demand_count allocated_count].each do |key|
        expect(report).to have_key(key)
      end
    end
  end

  describe '#to_h' do
    it 'includes demands array' do
      add_demand
      h = budget.to_h
      expect(h[:demands]).to be_an(Array)
      expect(h[:demands].size).to eq(1)
    end
  end

  describe '#find_demand' do
    it 'returns demand by id' do
      demand = add_demand
      expect(budget.find_demand(demand.id)).to eq(demand)
    end

    it 'returns nil for unknown id' do
      expect(budget.find_demand('nope')).to be_nil
    end
  end
end
