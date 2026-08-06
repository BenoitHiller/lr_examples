require 'forwardable'

module LrExamples
  class BiHash
    Inverted = Data.define(:value) do
      def inverted
        value
      end
    end

    module InverseRefinements
      refine Object do
        def inverted
          Inverted[self]
        end
      end
    end
    using InverseRefinements

    class InverseHash
      include Enumerable

      attr_reader :inverted

      def initialize(inverted)
        @inverted = inverted
      end

      def [](key)
        inverted[key.inverted]
      end

      def include?(key)
        inverted.include?(key.inverted)
      end

      def []=(key, value)
        inverted[value] = key
      end

      def delete(key)
        inverted.delete(key.inverted)
      end

      def each(&block)
        inverted.each(true).map { |key, value| [key.inverted, value] }.each(&block)
      end

      def keys
        map(&:first)
      end

      def length
        inverted.length
      end

      alias key? include?
    end

    include Enumerable
    extend Forwardable

    def_delegators :@data, :[], :key?, :include?

    attr_reader :inverted

    def initialize
      @data = {}
      @inverted = InverseHash.new(self)
    end

    def []=(key, value)
      if key?(key)
        @data.delete(@data[key].inverted)
      elsif key?(value.inverted)
        @data.delete(@data[value.inverted])
      end

      @data[key] = value
      @data[value.inverted] = key
    end

    def delete(key)
      if key?(key)
        @data.delete(@data[key].inverted)
        @data.delete(key)
      end
    end

    def each(inverted = false, &block)
      @data.filter { |key, _| key.is_a?(Inverted) == inverted }.each(&block)
    end

    def keys
      map(&:first)
    end

    def transform_values!(&block)
      each do |key, value|
        self[key] = block[value]
      end

      self
    end

    def length
      @data.length / 2
    end

    def report_print(rp)
      rp.inline do
        rp.write_header(self, write_id: false)
        rp.inline(" ") do
          rp.write("{")
          rp.write_object_id(self)
        end
      end
      rp.multiline(after: "}", separator: ",") do
        each do |key, value|
          rp.inline do
            rp.rp(key)
            rp.inline(" ") do
              rp.write("<=>")
              rp.rp(value)
            end
          end
        end
      end
    end
  end
end
