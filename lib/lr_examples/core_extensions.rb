module LrExamples
  module CoreExtensions
    refine Hash.singleton_class do
      def with_default(klass = nil, &block)
        if block
          self.new do |h, k|
            value = block.call
            if h.frozen?
              value.freeze
            else
              h[k] = value
            end
            value
          end
        elsif klass
          self.new do |h, k|
            value = klass.new
            if h.frozen?
              value.freeze
            else
              h[k] = value
            end
            value
          end
        else
          raise ArgumentError,
            "Neither a class nor a block was specified"
        end
      end
    end

    refine Array do
      def to_proc
        array = self

        Proc.new { |i| array[i] }
      end
    end
  end
end
