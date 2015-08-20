module Horza
  module Adapters
    module InstanceMethods

      def initialize(context)
        @context = context
      end

      def get(id)
        run_quietly { get!(id) }
      end

      def find_first(options = {})
        run_quietly { find_first!(options) }
      end

      def create(options = {})
        run_quietly { create!(options) }
      end

      def create_as_child(parent_id, options = {})
        run_quietly { create_as_child!(parent_id, options) }
      end

      def delete(id)
        run_quietly { delete!(id) }
      end

      def update(id, options = {})
        run_quietly { update!(id, options) }
      end

      protected

      def run_quietly(&block)
        block.call
      rescue *self.class.expected_horza_errors
      end

      # Execute the code block and convert ORM exceptions into Horza exceptions
      def run_and_convert_exceptions(&block)
        block.call
      rescue *self.class.expected_errors => e
        raise self.class.horza_error_from_orm_error(e.class).new(e.message)
      end

      def entity(res = @context)
        collection?(res) ? ::Horza::Entities.collection_entity_for(entity_symbol, res) :
          ::Horza::Entities.single_entity_for(entity_symbol, res)
      end

      def entity_symbol
        klass = @context.name.split('::').last
        collection? ? klass.pluralize.symbolize : klass.symbolize
      end

      # given an options hash,
      # with optional :conditions, :order, :limit and :offset keys,
      # returns conditions, normalized order, limit and offset
      def extract_conditions!(options = {})
        order      = normalize_order(options.delete(:order))
        limit      = options.delete(:limit)
        offset     = options.delete(:offset)
        conditions = options.delete(:conditions) || options

        [conditions, order, limit, offset]
      end

      # given an order argument, returns an array of pairs, with each pair containing the attribute, and :asc or :desc
      def normalize_order(order)
        order = Array(order)

        if order.length == 2 && !order[0].is_a?(Array) && [:asc, :desc].include?(order[1])
          order = [order]
        else
          order = order.map {|pair| pair.is_a?(Array) ? pair : [pair, :asc] }
        end

        order.each do |pair|
          pair.length == 2 or raise ArgumentError, "each order clause must be a pair (unknown clause #{pair.inspect})"
          [:asc, :desc].include?(pair[1]) or raise ArgumentError, "order must be specified with :asc or :desc (unknown key #{pair[1].inspect})"
        end

        order
      end

      def not_implemented_error
        self.class.not_implemented_error
      end
    end
  end
end
