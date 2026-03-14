# frozen_string_literal: true

require 'legion/extensions/attention_economy/version'
require 'legion/extensions/attention_economy/helpers/constants'
require 'legion/extensions/attention_economy/helpers/demand'
require 'legion/extensions/attention_economy/helpers/attention_budget'
require 'legion/extensions/attention_economy/runners/attention_economy'

module Legion
  module Extensions
    module AttentionEconomy
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
