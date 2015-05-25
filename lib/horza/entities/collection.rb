module Horza
  module Entities
    class Collection
      def initialize(collection)
        @collection = collection
      end

      def each
        @collection.each do |result|
          yield singular_entity(result)
        end
      end

      def [](index)
        singular_entity(@collection[index])
      end

      private

      def method_missing(method)
        if [:length, :size, :empty?, :present?].include? method
          @collection.send(method)
        elsif [:first, :last].include? method
          singular_entity(@collection.send(method))
        end
      end

      def singular_entity(record)
        adapter = Horza.adapter.new(record)
        singular_entity_class(record).new(adapter.to_hash)
      end

      # Collection classes have the form Horza::Entities::TypesMapper
      # Single output requires the form Horza::Entities::TypeMapper
      def singular_entity_class(record)
        @singular_entity ||= ::Horza::Entities::single_entity_for(record.class.name.split('::').last.symbolize)
      end
    end
  end
end
