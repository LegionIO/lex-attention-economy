# frozen_string_literal: true

require 'legion/extensions/attention_economy/helpers/demand'

RSpec.describe Legion::Extensions::AttentionEconomy::Helpers::Demand do
  subject(:demand) do
    described_class.new(label: 'test task', demand_type: :task, priority: 0.7, cost: 0.3, roi: 0.9)
  end

  describe '#initialize' do
    it 'assigns a uuid id' do
      expect(demand.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores label' do
      expect(demand.label).to eq('test task')
    end

    it 'stores demand_type' do
      expect(demand.demand_type).to eq(:task)
    end

    it 'clamps priority to [0.0, 1.0]' do
      d = described_class.new(label: 'x', demand_type: :task, priority: 1.5, cost: 0.1)
      expect(d.priority).to eq(1.0)
    end

    it 'clamps cost to [0.0, 1.0]' do
      d = described_class.new(label: 'x', demand_type: :task, priority: 0.5, cost: -0.1)
      expect(d.cost).to eq(0.0)
    end

    it 'clamps roi to [0.0, 1.0]' do
      d = described_class.new(label: 'x', demand_type: :task, priority: 0.5, cost: 0.1, roi: 2.0)
      expect(d.roi).to eq(1.0)
    end

    it 'defaults roi to 0.5' do
      d = described_class.new(label: 'x', demand_type: :task, priority: 0.5, cost: 0.1)
      expect(d.roi).to eq(0.5)
    end

    it 'starts with 0.0 allocated' do
      expect(demand.allocated).to eq(0.0)
    end

    it 'sets created_at' do
      expect(demand.created_at).to be_a(Time)
    end
  end

  describe '#allocate!' do
    it 'sets allocated amount' do
      demand.allocate!(amount: 0.25)
      expect(demand.allocated).to eq(0.25)
    end

    it 'clamps allocated to [0.0, 1.0]' do
      demand.allocate!(amount: 1.5)
      expect(demand.allocated).to eq(1.0)
    end
  end

  describe '#deallocate!' do
    it 'resets allocated to 0.0' do
      demand.allocate!(amount: 0.3)
      demand.deallocate!
      expect(demand.allocated).to eq(0.0)
    end
  end

  describe '#efficiency' do
    it 'computes roi / cost' do
      d = described_class.new(label: 'x', demand_type: :task, priority: 0.5, cost: 0.5, roi: 1.0)
      expect(d.efficiency).to eq(1.0)
    end

    it 'returns 0.0 when cost is zero' do
      d = described_class.new(label: 'x', demand_type: :task, priority: 0.5, cost: 0.0, roi: 0.8)
      expect(d.efficiency).to eq(0.0)
    end

    it 'clamps efficiency to [0.0, 1.0]' do
      d = described_class.new(label: 'x', demand_type: :task, priority: 0.5, cost: 0.1, roi: 1.0)
      expect(d.efficiency).to be <= 1.0
    end
  end

  describe '#efficiency_label' do
    it 'returns :excellent for high efficiency' do
      d = described_class.new(label: 'x', demand_type: :task, priority: 0.5, cost: 0.1, roi: 1.0)
      expect(d.efficiency_label).to eq(:excellent)
    end

    it 'returns :wasted for zero efficiency' do
      d = described_class.new(label: 'x', demand_type: :task, priority: 0.5, cost: 0.0, roi: 0.0)
      expect(d.efficiency_label).to eq(:wasted)
    end
  end

  describe '#priority_label' do
    it 'returns :critical for priority 0.9' do
      d = described_class.new(label: 'x', demand_type: :task, priority: 0.9, cost: 0.1)
      expect(d.priority_label).to eq(:critical)
    end

    it 'returns :high for priority 0.7' do
      d = described_class.new(label: 'x', demand_type: :task, priority: 0.7, cost: 0.1)
      expect(d.priority_label).to eq(:high)
    end

    it 'returns :background for priority 0.1' do
      d = described_class.new(label: 'x', demand_type: :task, priority: 0.1, cost: 0.1)
      expect(d.priority_label).to eq(:background)
    end
  end

  describe '#to_h' do
    it 'includes all fields' do
      h = demand.to_h
      expect(h).to include(:id, :label, :demand_type, :priority, :priority_label, :cost, :roi, :allocated, :efficiency, :efficiency_label, :created_at)
    end

    it 'priority_label is correct in to_h' do
      expect(demand.to_h[:priority_label]).to eq(:high)
    end
  end
end
