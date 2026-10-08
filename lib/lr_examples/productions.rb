module LrExamples
  class Productions
    class Token
      attr_reader :token

      def initialize(productions, token)
        @productions = productions
        @token = token
      end

      # rubocop:disable Naming/BinaryOperatorParameterName
      def <=(tokens)
        tokens = Array(tokens)
        values = tokens.map do |token|
          if token.is_a?(Token)
            token.token
          else
            token
          end
        end
        @productions.define(@token, values)
      end
      # rubocop:enable Naming/BinaryOperatorParameterName
    end

    class << self
      include Enumerable
      attr_reader :productions

      def inherited(subclass)
        super
        subclass.init
      end

      def init
        accept = Token.new(self, :$accept)
        start = Token.new(self, :S)
        @productions = [[accept.token, [start.token, "$"]]]
      end

      def define(left, right)
        @productions << [left, right]
      end

      def each(&block)
        @productions.each(&block)
      end

      def const_missing(name)
        Token.new(self, name)
      end
    end
  end
end
