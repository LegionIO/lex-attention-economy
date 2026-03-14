# frozen_string_literal: true

require 'legion/extensions/attention_economy/helpers/constants'
require 'legion/extensions/attention_economy/helpers/demand'
require 'legion/extensions/attention_economy/helpers/attention_budget'
require 'legion/extensions/attention_economy/runners/attention_economy'

module Legion
  module Extensions
    module AttentionEconomy
      class Client
        include Runners::AttentionEconomy

        def initialize(**)
          @attention_budget = Helpers::AttentionBudget.new
        end

        private

        attr_reader :attention_budget
      end
    end
  end
end
