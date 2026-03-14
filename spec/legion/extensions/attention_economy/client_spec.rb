# frozen_string_literal: true

require 'legion/extensions/attention_economy/client'

RSpec.describe Legion::Extensions::AttentionEconomy::Client do
  let(:client) { described_class.new }

  it 'responds to all runner methods' do
    expect(client).to respond_to(:add_demand)
    expect(client).to respond_to(:allocate_demand)
    expect(client).to respond_to(:deallocate_demand)
    expect(client).to respond_to(:recover_budget)
    expect(client).to respond_to(:prioritized_demands)
    expect(client).to respond_to(:best_roi_demands)
    expect(client).to respond_to(:rebalance_budget)
    expect(client).to respond_to(:attention_status)
    expect(client).to respond_to(:attention_snapshot)
  end

  it 'starts with empty demands' do
    expect(client.attention_status[:demand_count]).to eq(0)
  end

  it 'maintains isolated state per instance' do
    c1 = described_class.new
    c2 = described_class.new
    c1.add_demand(label: 'solo', demand_type: :task, priority: 0.5, cost: 0.1)
    expect(c2.attention_status[:demand_count]).to eq(0)
  end
end
