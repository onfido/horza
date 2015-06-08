module Horza
  module Adapters
    class Options
      META_METHODS = [:conditions, :limit, :offset, :order, :target, :id, :via]

      def initialize(options)
        @options = options
      end

      def method_missing(method)
        super unless META_METHODS.include? method
        @options[method]
      end

      def order_field
        return :id unless order.present?
        @options[:order].keys.first
      end

      def order_direction
        return :desc unless order.present?

        raise ::Horza::Errors::InvalidOption.new('Order must be :asc or :desc') unless [:asc, :desc].include?(@options[:order][order_field])
        order[order_field]
      end

      def eager_load?
        !!@options[:eager_load]
      end

      def eager_args
        raise ::Horza::Errors::InvalidOption.new('You must pass eager_load: true and defined a target') unless eager_load? && target
        return target unless via && via.present?

        via.reverse.reduce({}) do |hash, table|
          if hash.empty?
            hash.merge(table => target)
          else
            { table => hash }
          end
        end
      end
    end
  end
end
