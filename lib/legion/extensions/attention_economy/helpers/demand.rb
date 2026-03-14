# frozen_string_literal: true

require 'securerandom'
require_relative 'constants'

module Legion
  module Extensions
    module AttentionEconomy
      module Helpers
        class Demand
          include Constants

          attr_reader :id, :label, :demand_type, :priority, :cost, :roi, :created_at
          attr_accessor :allocated

          def initialize(label:, demand_type:, priority:, cost:, roi: 0.5)
            @id          = SecureRandom.uuid
            @label       = label
            @demand_type = demand_type
            @priority    = priority.clamp(0.0, 1.0)
            @cost        = cost.clamp(0.0, 1.0)
            @roi         = roi.clamp(0.0, 1.0)
            @allocated   = 0.0
            @created_at  = Time.now.utc
          end

          def allocate!(amount:)
            @allocated = amount.clamp(0.0, 1.0).round(10)
          end

          def deallocate!
            @allocated = 0.0
          end

          def efficiency
            return 0.0 if cost.zero?

            (roi / cost).clamp(0.0, 1.0).round(10)
          end

          def efficiency_label
            Constants::EFFICIENCY_LABELS.find { |range, _| range.cover?(efficiency) }&.last || :wasted
          end

          def priority_label
            Constants::PRIORITY_LABELS.find { |range, _| range.cover?(priority) }&.last || :background
          end

          def to_h
            {
              id:               id,
              label:            label,
              demand_type:      demand_type,
              priority:         priority,
              priority_label:   priority_label,
              cost:             cost,
              roi:              roi,
              allocated:        allocated,
              efficiency:       efficiency,
              efficiency_label: efficiency_label,
              created_at:       created_at
            }
          end
        end
      end
    end
  end
end
