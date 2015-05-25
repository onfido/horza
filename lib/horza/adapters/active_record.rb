module Horza
  module Adapters
    class ActiveRecord < AbstractAdapter
      class << self
        def expected_errors
          [::ActiveRecord::RecordNotFound]
        end

        def context_for_entity(entity)
          entity_context_map[entity]
        end

        def entity_context_map
          @map ||= ::Horza.descendants_map(::ActiveRecord::Base)
        end
      end

      def get!(id)
        entity_class(@context.find(id).attributes)
      end

      def find_first!(options = {})
        entity_class(base_query(options).first!.attributes)
      end

      def find_all(options = {})
        entity_class(base_query(options))
      end

      def ancestors(options = {})
        result = walk_family_tree(@context.find(options[:id]), options)

        return nil unless result

        collection?(result) ? entity_class(result) : entity_class(result.attributes)
      rescue NoMethodError
        raise ::Horza::Errors::InvalidAncestry.new('Invalid relation. Ensure that the plurality of your associations is correct.')
      end

      # Where to put this?
      def to_hash
        raise ::Horza::Errors::CannotGetHashFromCollection.new if collection?
        @context.attributes
      rescue NoMethodError
        raise ::Horza::Errors::QueryNotYetPerformed.new
      end

      private

      def base_query(options)
        @context.where(options[:conditions]).order('ID DESC')
      end

      def collection?(subject = @context)
        subject.is_a? ::ActiveRecord::Relation
      end

      def walk_family_tree(object, options)
        via = options[:via] || []
        via.push(options[:result_key]).reduce(object) { |object, relation| object.send(relation) }
      end
    end
  end
end
