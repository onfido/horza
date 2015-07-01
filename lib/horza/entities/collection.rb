module Horza
  module Entities
    class Collection
      def initialize(collection)
        @collection = collection
      end

      def [](index)
        singular_entity(@collection[index])
      end

      private

      def method_missing(method, &block)
        if [:length, :size, :empty?, :present?].include? method
          @collection.send(method)
        elsif [:first, :last, :pop].include? method
          singular_entity(@collection.send(method))
        elsif [:each, :map, :collect]
          enum_method(method, &block)
        end
      end

      def enum_method(method, &block)
        @collection.send(method) do |result|
          yield singular_entity(result)
        end
      end

      def singular_entity(record)
        adapter = Horza.adapter.new(record)
        singular_entity_class(record).new(adapter.to_hash)
      end

      # Collection classes have the form Horza::Entities::Users
      # Single output requires the form Horza::Entities::User
      def singular_entity_class(record)
        @singular_entity ||= ::Horza::Entities::single_entity_for(record.class.name.split('::').last.symbolize)
      end
    end
  end
end
