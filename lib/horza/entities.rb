module Horza
  module Entities
    class << self
      def single_entity_for(entity_symbol, attributes)
        klass = single_entities[entity_symbol] || Horza.adapter.single_entity_klass
        klass.new(attributes)
      end

      def single_entities
        @singles ||= ::Horza.descendants_map(::Horza::Entities::Single)
      end

      def collection_entity_for(entity_symbol, attributes)
        klass = collection_entities[entity_symbol] || Horza.adapter.collection_entity_klass
        klass.new(attributes)
      end

      def collection_entities
        @collections ||= ::Horza.descendants_map(::Horza::Entities::Collection)
      end
    end
  end
end
