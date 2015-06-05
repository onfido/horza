module Horza
  module Adapters
    class Options
      META_METHODS = [:conditions, :limit, :offset, :target, :id, :via]

      def initialize(options)
        @options = options
      end

      def method_missing(method)
        super unless META_METHODS.include? method
        @options[method]
      end

      def order_field
        return :id unless @options[:order].present?
        @options[:order].keys.first
      end

      def order_direction
        return :desc unless @options[:order].present?

        raise ::Horza::Errors::InvalidOption.new('Order must be :asc or :desc') unless [:asc, :desc].include?(@options[:order][order_field])
        @options[:order][order_field]
      end

      def eager_load?
        !!@options[:eager_load]
      end
    end
  end
end
