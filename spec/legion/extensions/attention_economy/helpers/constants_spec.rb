# frozen_string_literal: true

require 'legion/extensions/attention_economy/helpers/demand'

RSpec.describe Legion::Extensions::AttentionEconomy::Helpers::Constants do
  describe 'MAX_DEMANDS' do
    it 'is 200' do
      expect(described_class::MAX_DEMANDS).to eq(200)
    end
  end

  describe 'DEFAULT_BUDGET' do
    it 'is 1.0' do
      expect(described_class::DEFAULT_BUDGET).to eq(1.0)
    end
  end

  describe 'BUDGET_RECOVERY_RATE' do
    it 'is 0.05' do
      expect(described_class::BUDGET_RECOVERY_RATE).to eq(0.05)
    end
  end

  describe 'MIN_ALLOCATION' do
    it 'is 0.01' do
      expect(described_class::MIN_ALLOCATION).to eq(0.01)
    end
  end

  describe 'PRIORITY_LABELS via Demand#priority_label' do
    def demand_with_priority(pri)
      Legion::Extensions::AttentionEconomy::Helpers::Demand.new(
        label: 'x', demand_type: :task, priority: pri, cost: 0.1
      )
    end

    it 'labels 0.9 as critical' do
      expect(demand_with_priority(0.9).priority_label).to eq(:critical)
    end

    it 'labels 0.7 as high' do
      expect(demand_with_priority(0.7).priority_label).to eq(:high)
    end

    it 'labels 0.5 as moderate' do
      expect(demand_with_priority(0.5).priority_label).to eq(:moderate)
    end

    it 'labels 0.3 as low' do
      expect(demand_with_priority(0.3).priority_label).to eq(:low)
    end

    it 'labels 0.1 as background' do
      expect(demand_with_priority(0.1).priority_label).to eq(:background)
    end

    it 'labels boundary 0.8 as critical' do
      expect(demand_with_priority(0.8).priority_label).to eq(:critical)
    end

    it 'labels boundary 0.6 as high' do
      expect(demand_with_priority(0.6).priority_label).to eq(:high)
    end
  end

  describe 'EFFICIENCY_LABELS via Demand#efficiency_label' do
    def demand_with_efficiency(roi, cost)
      Legion::Extensions::AttentionEconomy::Helpers::Demand.new(
        label: 'x', demand_type: :task, priority: 0.5, cost: cost, roi: roi
      )
    end

    it 'labels 0.9 efficiency as excellent' do
      d = demand_with_efficiency(0.9, 1.0)
      expect(d.efficiency_label).to eq(:excellent)
    end

    it 'labels 0.7 efficiency as good' do
      d = demand_with_efficiency(0.7, 1.0)
      expect(d.efficiency_label).to eq(:good)
    end

    it 'labels 0.5 efficiency as adequate' do
      d = demand_with_efficiency(0.5, 1.0)
      expect(d.efficiency_label).to eq(:adequate)
    end

    it 'labels 0.3 efficiency as poor' do
      d = demand_with_efficiency(0.3, 1.0)
      expect(d.efficiency_label).to eq(:poor)
    end

    it 'labels 0.1 efficiency as wasted' do
      d = demand_with_efficiency(0.1, 1.0)
      expect(d.efficiency_label).to eq(:wasted)
    end
  end

  describe 'DEMAND_TYPES' do
    it 'includes all six types' do
      expect(described_class::DEMAND_TYPES).to include(:task, :sensory, :social, :emotional, :cognitive, :maintenance)
    end

    it 'is frozen' do
      expect(described_class::DEMAND_TYPES).to be_frozen
    end

    it 'has exactly six types' do
      expect(described_class::DEMAND_TYPES.size).to eq(6)
    end
  end
end
