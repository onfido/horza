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
        DependencyLoading.resolve_dependency(entity.to_s)
      end

      def not_implemented_error
        raise ::Horza::Errors::MethodNotImplemented, 'You must implement this method in your adapter.'
      end

      def single_entity_klass
        ::Horza::Entities::Single
      end

      def collection_entity_klass
        ::Horza::Entities::Collection
      end
    end
  end
end
