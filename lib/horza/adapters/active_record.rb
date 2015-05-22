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
          @map ||= ::ActiveRecord::Base.descendants.reduce({}) { |hash, (klass)| hash.merge(klass.name.split('::').last.underscore.to_sym => klass) }
        end
      end

      def get!(id, result = nil)
        new_result(actor(result).find(id))
      end

      def find_first(options = {}, result = nil)
        res = actor(result).where(options[:conditions]).order('ID DESC').first!
        result ? res : new_result(res)
      end

      def find_all(options = {}, result = nil)
        res = actor(result).where(options[:conditions]).order('ID DESC')
        result ? res : new_result(res)
      end

      def ancestors(options = {}, result = nil)
        res = walk_family_tree(actor(result).find(options[:id]), options)
        result ? res : new_result(res)
      rescue NoMethodError
        raise ::Horza::Errors::InvalidAncestry.new('Invalid relation. Ensure that the plurality of your associations is correct.')
      end

      def to_hash
        raise ::Horza::Errors::CannotGetHashFromCollection.new if @context.is_a? ::ActiveRecord::Relation
        @context.attributes
      rescue NoMethodError
        raise ::Horza::Errors::QueryNotYetPerformed.new
      end

      private

      def walk_family_tree(object, options)
        via = options[:via] || []
        via.push(options[:result_key]).reduce(object) { |object, relation| object.send(relation) }
      end
    end
  end
end
