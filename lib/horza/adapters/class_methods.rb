module Horza
  module Adapters
    module ClassMethods
      def expected_horza_errors
        [Horza::Errors::RecordNotFound, Horza::Errors::RecordInvalid]
      end

      def expected_errors
        expected_errors_map.keys
      end

      def horza_error_from_orm_error(orm_error)
        expected_errors_map[orm_error]
      end

      def context_for_entity(entity)
        entity_context_map[entity]
      end

      def not_implemented_error
        raise ::Horza::Errors::MethodNotImplemented, 'You must implement this method in your adapter.'
      end
    end
  end
end
