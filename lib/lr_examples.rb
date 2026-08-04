require 'amazing_print'
require 'report_print'

require_relative "lr_examples/version"
require_relative "lr_examples/core_extensions"
require_relative "lr_examples/memoized"
require_relative "lr_examples/bi_hash"
require_relative "lr_examples/lr0"
require_relative "lr_examples/lalr"
require_relative "lr_examples/productions"

module LrExamples
  class Error < StandardError; end
end
