module Horza
  module Adapters
    class AbstractAdapter
      attr_reader :context

      class << self
        def expected_errors
          [::Horza::Errors::RecordNotFound, ::Horza::Errors::RecordInvalid]
        end

        def context_for_entity(entity)
          not_implemented_error
        end

        def entity_context_map
          not_implemented_error
        end

        def not_implemented_error
          raise ::Horza::Errors::MethodNotImplemented, 'You must implement this method in your adapter.'
        end
      end

      def initialize(context)
        @context = context
      end

      def get(options = {})
        get!(options)
      rescue *self.class.expected_errors
      end

      def get!(options = {})
        not_implemented_error
      end

      def find_first(options = {})
        find_first!(options)
      rescue *self.class.expected_errors
      end

      def find_first!(options = {})
        not_implemented_error
      end

      def find_all(options = {})
        not_implemented_error
      end

      def create(options = {})
        create!(options)
      rescue *self.class.expected_errors
      end

      def create!(options = {})
        not_implemented_error
      end

      def delete(id)
        delete!(id)
      rescue *self.class.expected_errors
      end

      def delete!(id)
        not_implemented_error
      end

      def update(id, options = {})
        update!(id, options)
      rescue *self.class.expected_errors
      end

      def update!(id, options = {})
        not_implemented_error
      end

      def ancestors(options = {})
        not_implemented_error
      end

      def eager_load(options = {})
        not_implemented_error
      end

      def to_hash
        not_implemented_error
      end

      def entity_class(res = @context)
        collection?(res) ? ::Horza::Entities.collection_entity_for(entity_symbol).new(res) : ::Horza::Entities.single_entity_for(entity_symbol).new(res)
      end

      private

      def not_implemented_error
        self.class.not_implemented_error
      end

      def entity_symbol
        klass = @context.name.split('::').last
        collection? ? klass.pluralize.symbolize : klass.symbolize
      end
    end
  end
end
