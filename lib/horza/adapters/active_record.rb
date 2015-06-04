module Horza
  module Adapters
    class ActiveRecord < AbstractAdapter
      INVALID_ANCESTRY_MSG = 'Invalid relation. Ensure that the plurality of your associations is correct.'

      class << self
        def entity_context_map
          @map ||= ::Horza.descendants_map(::ActiveRecord::Base)
        end

        def expected_errors_map
          {
            ::ActiveRecord::RecordNotFound => Horza::Errors::RecordNotFound,
            ::ActiveRecord::RecordInvalid => Horza::Errors::RecordInvalid
          }
        end
      end

      def get!(id)
        run_and_convert_exceptions { entity_class(@context.find(id).attributes) }
      end

      def find_first!(options = {})
        run_and_convert_exceptions { entity_class(base_query(options).first!.attributes) }
      end

      def find_all(options = {})
        run_and_convert_exceptions { entity_class(base_query(options)) }
      end

      def create!(options = {})
        run_and_convert_exceptions do
          record = @context.new(options)
          record.save!
          entity_class(record.attributes)
        end
      end

      def update!(id, options = {})
        run_and_convert_exceptions do
          record = @context.find(id)
          record.assign_attributes(options)
          record.save!
          entity_class(record.attributes)
        end
      end

      def delete!(id)
        run_and_convert_exceptions do
          record = @context.find(id)
          record.destroy!
          true
        end
      end

      def ancestors(options = {})
        run_and_convert_exceptions do
          result = walk_family_tree(@context.find(options[:id]), options)

          return nil unless result

          collection?(result) ? entity_class(result) : entity_class(result.attributes)
        end
      end

      def to_hash
        raise ::Horza::Errors::CannotGetHashFromCollection.new if collection?
        raise ::Horza::Errors::QueryNotYetPerformed.new unless @context.respond_to?(:attributes)
        @context.attributes
      end

      private

      def base_query(options)
        @context.where(options).order('ID DESC')
      end

      def collection?(subject = @context)
        subject.is_a?(::ActiveRecord::Relation) || subject.is_a?(Array)
      end

      def walk_family_tree(object, options)
        via = options[:via] || []
        via.push(options[:target]).reduce(object) do |object, relation|
          raise ::Horza::Errors::InvalidAncestry.new(INVALID_ANCESTRY_MSG) unless object.respond_to? relation
          object.send(relation)
        end
      end
    end
  end
end
