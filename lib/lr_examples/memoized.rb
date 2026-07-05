module LrExamples
  module Memoized
    module ClassMethods
      def memoized_method(name, &block)
        if block.arity > 0
          raise Error.new(
            "memoizing methods with arguments is not yet supported"
          )
        end
        cache_name = :"@memo__#{name}"

        define_method(name) do
          unless instance_variable_defined?(cache_name)
            instance_variable_set(cache_name, instance_eval(&block))
          end

          instance_variable_get(cache_name)
        end
      end
    end

    def self.included(target)
      target.extend(ClassMethods)
    end
  end
end
