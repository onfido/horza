module Horza
  module Entities
    class << self

      def single_entity_for(entity_symbol)
        single_entities[entity_symbol] || ::Horza::Entities::Single
      end

      def single_entities
        @singles ||= ::Horza.descendants_map(::Horza::Entities::Single)
      end

      def collection_entity_for(entity_symbol)
        collection_entities[entity_symbol] || ::Horza::Entities::Collection
      end

      def collection_entities
        @singles ||= ::Horza.descendants_map(::Horza::Entities::Collection)
      end
    end
  end
end
