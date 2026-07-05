module LrExamples
  module CoreExtensions
    refine Hash.singleton_class do
      def with_default(klass = nil, &block)
        if block
          self.new { |h, k| h[k] = block.call }
        elsif klass
          self.new { |h, k| h[k] = klass.new }
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
