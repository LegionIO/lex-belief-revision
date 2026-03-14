# frozen_string_literal: true

require 'legion/extensions/belief_revision/version'
require 'legion/extensions/belief_revision/helpers/constants'
require 'legion/extensions/belief_revision/helpers/evidence'
require 'legion/extensions/belief_revision/helpers/belief'
require 'legion/extensions/belief_revision/helpers/belief_network'
require 'legion/extensions/belief_revision/runners/belief_revision'
require 'legion/extensions/belief_revision/client'

module Legion
  module Extensions
    module Helpers
      module Lex; end
    end
  end
end

module Legion
  module Logging
    def self.method_missing(*); end
    def self.respond_to_missing?(*) = true
  end
end
