module LrExamples
  module Memoized
    class Memoizer < Module; end
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

        unless defined? @memoizer
          @memoizer = Memoizer.new
          prepend @memoizer
        end

        cache_name = :"@memo__#{name}"

        @memoizer.module_exec do
          define_method(name) do
            unless instance_variable_defined?(cache_name)

              value = super()

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
    end

    def self.included(target)
      target.extend(ClassMethods)
    end
  end
end
