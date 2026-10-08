module LrExamples
  module Memoized
    module ClassMethods
      def memoized(*args)
        freeze_cache = false
        case args
        in :frozen, Symbol => name
          freeze_cache = true
        in [Symbol => name]
        else
          raise ArgumentError,
            "accepts either a method name or :freeze, method_name"
        end

        inner_method = instance_method(name)
        cache_name = :"@memo__#{name}"

        define_method(name) do
          unless instance_variable_defined?(cache_name)

            value = inner_method.bind_call(self)

            if freeze_cache
              value.freeze
            end

            instance_variable_set(
              cache_name,
              value
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
