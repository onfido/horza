module Horza
  module Adapters
    class ActiveRecord < AbstractAdapter
      INVALID_ANCESTRY_MSG = 'Invalid relation. Ensure that the plurality of your associations is correct.'
      CONTEXT_NAMESPACE = ::ActiveRecord::Base

      class << self
        def entity_context_map
          # Rails doesn't preload classes in development mode, caching doesn't make sense
          return ::Horza.descendants_map(CONTEXT_NAMESPACE) if ::Horza.configuration.development_mode
          @map ||= ::Horza.descendants_map(CONTEXT_NAMESPACE)
        end

        def expected_errors_map
          {
            ::ActiveRecord::RecordNotFound => Horza::Errors::RecordNotFound,
            ::ActiveRecord::RecordInvalid => Horza::Errors::RecordInvalid,
            ::ActiveRecord::UnknownAttributeError => Horza::Errors::UnknownAttributeError
          }
        end
      end

      def get!(id)
        run_and_convert_exceptions { entity_class(@context.find(id).attributes) }
      end

      def find_first!(options = {})
        run_and_convert_exceptions { entity_class(query(options).first!.attributes) }
      end

      def find_all(options = {})
        run_and_convert_exceptions { entity_class(query(options)) }
      end

      def create!(options = {})
        run_and_convert_exceptions do
          record = @context.new(options)
          record.save!
          entity_class(record.attributes)
        end
      end

      def create_as_child!(parent_args, options = {})
        run_and_convert_exceptions do
          parent = Horza.adapter.context_for_entity(parent_args[:klass]).find(parent_args[:id])
          create!(options.merge(parent_args[:klass] => parent))
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
          record.destroy
          true
        end
      end

      def association(options = {})
        run_and_convert_exceptions do
          options = Options.new(options)

          base = @context
          base = base.includes(options.eager_args) if options.eager_load?
          base = base.find(options.id)

          result = walk_family_tree(base, options)
          return nil unless result

          collection?(result) ? entity_class(query(options, result)) : entity_class(result.attributes)
        end
      end

      def to_hash
        raise ::Horza::Errors::CannotGetHashFromCollection.new if collection?
        raise ::Horza::Errors::QueryNotYetPerformed.new unless @context.respond_to?(:attributes)
        @context.attributes
      end

      private

      def query(options, base = @context)
        options = options.is_a?(Options) ? options : Options.new(options)

        result = base
        result = base.where(options.conditions) if options.conditions
        result = result.order(base.arel_table[options.order_field].send(options.order_direction))
        result = result.limit(options.limit) if options.limit
        result = result.offset(options.offset) if options.offset
        result
      end

      def collection?(subject = @context)
        subject.is_a?(::ActiveRecord::Relation) || subject.is_a?(Array)
      end

      def walk_family_tree(object, options)
        via = options.via || []

        via.push(options.target).reduce(object) do |object, relation|
          raise ::Horza::Errors::InvalidAncestry.new(INVALID_ANCESTRY_MSG) unless object.respond_to? relation
          object.send(relation)
        end
      end
    end
  end
end
