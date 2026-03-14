# frozen_string_literal: true

require 'legion/extensions/attention_economy/client'

RSpec.describe Legion::Extensions::AttentionEconomy::Runners::AttentionEconomy do
  let(:client) { Legion::Extensions::AttentionEconomy::Client.new }

  def add_task(label: 'test', demand_type: :task, priority: 0.5, cost: 0.2, roi: 0.6)
    client.add_demand(label: label, demand_type: demand_type, priority: priority, cost: cost, roi: roi)
  end

  describe '#add_demand' do
    it 'returns created: true on success' do
      result = add_task
      expect(result[:created]).to be true
    end

    it 'returns demand hash on success' do
      result = add_task
      expect(result[:demand]).to include(:id, :label, :priority, :cost, :roi)
    end

    it 'returns created: false for invalid demand_type' do
      result = client.add_demand(label: 'x', demand_type: :invalid, priority: 0.5, cost: 0.1)
      expect(result[:created]).to be false
      expect(result[:reason]).to include('demand_type')
    end

    it 'supports all valid demand types' do
      %i[task sensory social emotional cognitive maintenance].each do |type|
        result = client.add_demand(label: type.to_s, demand_type: type, priority: 0.5, cost: 0.1)
        expect(result[:created]).to be true
      end
    end
  end

  describe '#allocate_demand' do
    it 'allocates existing demand' do
      demand_id = add_task[:demand][:id]
      result = client.allocate_demand(demand_id: demand_id)
      expect(result[:allocated]).to be true
    end

    it 'includes remaining budget in result' do
      demand_id = add_task(cost: 0.3)[:demand][:id]
      result = client.allocate_demand(demand_id: demand_id)
      expect(result[:remaining]).to be_within(0.001).of(0.7)
    end

    it 'returns allocated: false for unknown demand' do
      result = client.allocate_demand(demand_id: 'nonexistent')
      expect(result[:allocated]).to be false
    end

    it 'supports explicit amount override' do
      demand_id = add_task(cost: 0.3)[:demand][:id]
      result = client.allocate_demand(demand_id: demand_id, amount: 0.1)
      expect(result[:amount]).to eq(0.1)
    end
  end

  describe '#deallocate_demand' do
    it 'deallocates allocated demand' do
      demand_id = add_task(cost: 0.3)[:demand][:id]
      client.allocate_demand(demand_id: demand_id)
      result = client.deallocate_demand(demand_id: demand_id)
      expect(result[:deallocated]).to be true
    end

    it 'frees the allocated amount' do
      demand_id = add_task(cost: 0.3)[:demand][:id]
      client.allocate_demand(demand_id: demand_id)
      result = client.deallocate_demand(demand_id: demand_id)
      expect(result[:freed]).to be_within(0.001).of(0.3)
    end
  end

  describe '#recover_budget' do
    it 'recovers budget using default rate' do
      demand_id = add_task(cost: 0.3)[:demand][:id]
      client.allocate_demand(demand_id: demand_id)
      result = client.recover_budget
      expect(result[:recovered]).to be > 0
    end

    it 'accepts custom recovery amount' do
      demand_id = add_task(cost: 0.5)[:demand][:id]
      client.allocate_demand(demand_id: demand_id)
      result = client.recover_budget(amount: 0.2)
      expect(result[:spent]).to be_within(0.001).of(0.3)
    end
  end

  describe '#prioritized_demands' do
    it 'returns demands sorted by priority descending' do
      client.add_demand(label: 'low', demand_type: :task, priority: 0.1, cost: 0.1)
      client.add_demand(label: 'high', demand_type: :task, priority: 0.9, cost: 0.1)
      result = client.prioritized_demands
      expect(result[:demands].first[:priority]).to be >= result[:demands].last[:priority]
    end

    it 'returns count of demands' do
      add_task(label: 'a')
      add_task(label: 'b')
      expect(client.prioritized_demands[:count]).to eq(2)
    end
  end

  describe '#best_roi_demands' do
    it 'returns top demands by efficiency' do
      client.add_demand(label: 'poor', demand_type: :task, priority: 0.5, cost: 0.9, roi: 0.1)
      client.add_demand(label: 'great', demand_type: :task, priority: 0.5, cost: 0.1, roi: 0.9)
      result = client.best_roi_demands(limit: 1)
      expect(result[:demands].first[:label]).to eq('great')
    end

    it 'defaults limit to 5' do
      6.times { |i| add_task(label: "d#{i}") }
      result = client.best_roi_demands
      expect(result[:count]).to eq(5)
    end
  end

  describe '#rebalance_budget' do
    it 'returns rebalanced key' do
      result = client.rebalance_budget
      expect(result).to have_key(:rebalanced)
    end

    it 'returns 0 when not over budget' do
      result = client.rebalance_budget
      expect(result[:rebalanced]).to eq(0)
    end
  end

  describe '#attention_status' do
    it 'returns budget report keys' do
      result = client.attention_status
      %i[total_budget spent available utilization demand_count].each do |key|
        expect(result).to have_key(key)
      end
    end

    it 'reflects demand count' do
      add_task
      expect(client.attention_status[:demand_count]).to eq(1)
    end
  end

  describe '#attention_snapshot' do
    it 'includes demands array' do
      add_task
      result = client.attention_snapshot
      expect(result[:demands]).to be_an(Array)
      expect(result[:demands].size).to eq(1)
    end

    it 'includes budget metrics' do
      result = client.attention_snapshot
      expect(result).to include(:total_budget, :spent, :available)
    end
  end
end
