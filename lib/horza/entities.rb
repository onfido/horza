module Horza
  module Entities
    class << self
      def single_entity_for(entity_symbol, attributes)
        klass = single_entities[entity_symbol] || single_entity_klass
        klass.new(attributes)
      end

      def single_entities
        @singles ||= ::Horza.descendants_map(::Horza::Entities::Single)
      end

      def collection_entity_for(entity_symbol, attributes)
        klass = collection_entities[entity_symbol] || collection_entity_klass
        klass.new(attributes)
      end

      def collection_entities
        @collections ||= ::Horza.descendants_map(::Horza::Entities::Collection)
      end

      def single_entity_klass
        entity_klass(:single)
      end

      def collection_entity_klass
        entity_klass(:collection)
      end

      private

      def entity_klass(type)
        if ::Horza.configuration.adapter == :active_record
          "::Horza::Entities::#{type.to_s.titleize}WithActiveModel".constantize
        else
          "::Horza::Entities::#{type.to_s.titleize}With#{::Horza.configuration.adapter.to_s.titleize.gsub(/\s+/,'')}".constantize
        end
      rescue NameError
        "::Horza::Entities::#{type.to_s.titleize}".constantize
      end
    end
  end
end
