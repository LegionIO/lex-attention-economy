# frozen_string_literal: true

module Legion
  module Extensions
    module AttentionEconomy
      module Helpers
        module Constants
          MAX_DEMANDS           = 200
          DEFAULT_BUDGET        = 1.0
          BUDGET_RECOVERY_RATE  = 0.05
          MIN_ALLOCATION        = 0.01

          PRIORITY_LABELS = {
            (0.8..)     => :critical,
            (0.6...0.8) => :high,
            (0.4...0.6) => :moderate,
            (0.2...0.4) => :low,
            (..0.2)     => :background
          }.freeze

          EFFICIENCY_LABELS = {
            (0.8..)     => :excellent,
            (0.6...0.8) => :good,
            (0.4...0.6) => :adequate,
            (0.2...0.4) => :poor,
            (..0.2)     => :wasted
          }.freeze

          DEMAND_TYPES = %i[task sensory social emotional cognitive maintenance].freeze
        end
      end
    end
  end
end
