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
        context = entity_context_map[entity]
        return context if context

        lazy_load_model(entity)
      end

      def lazy_load_model(entity)
        #raise Horza::Errors::NoContextForEntity.new unless Horza.configuration.development_mode
        lazy_const = entity.to_s.camelize

        [Object].concat(Horza.configuration.namespaces).each do |namespace|
          begin
            return namespace.const_get(lazy_const) if (namespace.const_get(lazy_const) < Horza.adapter::CONTEXT_NAMESPACE)
          rescue NameError
            next
          end
        end

        raise Horza::Errors::NoContextForEntity.new
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
