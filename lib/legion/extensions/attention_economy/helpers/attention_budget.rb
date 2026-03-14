# frozen_string_literal: true

require_relative 'constants'
require_relative 'demand'

module Legion
  module Extensions
    module AttentionEconomy
      module Helpers
        class AttentionBudget
          include Constants

          attr_reader :total_budget, :spent, :recovered

          def initialize(total_budget: Constants::DEFAULT_BUDGET)
            @demands       = {}
            @total_budget  = total_budget
            @spent         = 0.0
            @recovered     = 0.0
          end

          def create_demand(label:, demand_type:, priority:, cost:, roi: 0.5)
            raise ArgumentError, "demand_type must be one of #{Constants::DEMAND_TYPES.inspect}" unless Constants::DEMAND_TYPES.include?(demand_type)
            raise ArgumentError, "max demands (#{Constants::MAX_DEMANDS}) reached" if @demands.size >= Constants::MAX_DEMANDS

            demand = Demand.new(label: label, demand_type: demand_type, priority: priority, cost: cost, roi: roi)
            @demands[demand.id] = demand
            demand
          end

          def allocate(demand_id:, amount: nil)
            demand = @demands.fetch(demand_id, nil)
            return { allocated: false, reason: :not_found } unless demand

            alloc_amount = (amount || demand.cost).clamp(Constants::MIN_ALLOCATION, 1.0)

            return { allocated: false, reason: :insufficient_budget, available: available_budget.round(10) } if alloc_amount > available_budget

            demand.allocate!(amount: alloc_amount)
            @spent = (@spent + alloc_amount).round(10)
            { allocated: true, demand_id: demand_id, amount: alloc_amount, remaining: available_budget.round(10) }
          end

          def deallocate(demand_id:)
            demand = @demands.fetch(demand_id, nil)
            return { deallocated: false, reason: :not_found } unless demand

            freed = demand.allocated
            demand.deallocate!
            @spent = [(@spent - freed).round(10), 0.0].max
            { deallocated: true, demand_id: demand_id, freed: freed.round(10), remaining: available_budget.round(10) }
          end

          def recover!(amount: Constants::BUDGET_RECOVERY_RATE)
            previous = @spent
            @spent   = [(@spent - amount).round(10), 0.0].max
            delta    = (previous - @spent).round(10)
            @recovered = (@recovered + delta).round(10)
            { recovered: delta, spent: @spent, available: available_budget.round(10) }
          end

          def available_budget
            (@total_budget - @spent).clamp(0.0, @total_budget).round(10)
          end

          def utilization
            return 0.0 if @total_budget.zero?

            (@spent / @total_budget).clamp(0.0, 1.0).round(10)
          end

          def prioritized_demands
            @demands.values.sort_by { |d| -d.priority }
          end

          def best_roi(limit: 5)
            @demands.values
                    .sort_by { |d| -d.efficiency }
                    .first(limit)
          end

          def over_budget?
            @spent > @total_budget
          end

          def budget_pressure
            utilization
          end

          def rebalance
            return { rebalanced: 0 } unless over_budget?

            sorted = @demands.values.select { |d| d.allocated.positive? }.sort_by(&:priority)
            freed_count = 0

            sorted.each do |demand|
              break unless over_budget?

              freed = demand.allocated
              demand.deallocate!
              @spent = [(@spent - freed).round(10), 0.0].max
              freed_count += 1
            end

            { rebalanced: freed_count, spent: @spent, available: available_budget.round(10) }
          end

          def budget_report
            {
              total_budget:    @total_budget,
              spent:           @spent.round(10),
              available:       available_budget,
              utilization:     utilization,
              recovered:       @recovered.round(10),
              over_budget:     over_budget?,
              budget_pressure: budget_pressure,
              demand_count:    @demands.size,
              allocated_count: @demands.values.count { |d| d.allocated.positive? }
            }
          end

          def to_h
            budget_report.merge(
              demands: @demands.values.map(&:to_h)
            )
          end

          def demands
            @demands.values
          end

          def find_demand(demand_id)
            @demands[demand_id]
          end
        end
      end
    end
  end
end
