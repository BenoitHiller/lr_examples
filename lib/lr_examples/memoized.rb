module LrExamples
  module Memoized
    module ClassMethods
      def memoized(name)
        inner_method = instance_method(name)
        cache_name = :"@memo__#{name}"

        define_method(name) do
          unless instance_variable_defined?(cache_name)
            instance_variable_set(
              cache_name,
              inner_method.bind_call(self)
            )
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
