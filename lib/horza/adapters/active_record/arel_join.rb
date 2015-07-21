module Horza
  module Adapters
    class ArelJoin < Options

      class << self
        def sql(context, options)
          new(context, options).query.to_sql
        end
      end

      def initialize(context, options)
        @options = options

        @base_table_key = context.table_name.to_sym
        @join_table_key = options[:with]

        @base_table = Arel::Table.new(@base_table_key)
        @join_table = Arel::Table.new(@join_table_key)
      end

      def query
        join = @base_table.project(fields).join(@join_table).on(predicates)
        join = join.where(where_clause(@base_table, @base_table_key)) if conditions_for_table?(@base_table_key)
        join = join.where(where_clause(@join_table, @join_table_key)) if conditions_for_table?(@join_table_key)
        join = join.take(@options[:limit]) if @options[:limit]
        join = join.skip(@options[:offset]) if @options[:offset]
        join
      end

      private

      def fields
        return [@base_table[:id], Arel.star] unless @options[:fields] && @options[:fields].present?

        @options[:fields].map do |table, fields|
          fields.map do |field|
            case table
            when @base_table_key
              alias_field(@base_table, field)
            when @join_table_key
              alias_field(@join_table, field)
            end
          end
        end
      end

      def alias_field(table, field)
        return table[field.to_s] unless field.is_a?(Hash)
        table[field.keys.first.to_s].as(field.values.first.to_s)
      end

      def predicates
        @options[:on] = [@options[:on]] unless @options[:on].is_a?(Array)

        predicate_list = @options[:on].map { |on| predicate(on) }.flatten
        chain_with_method(predicate_list, :and)
      end

      def predicate(on)
        on.map { |base_field, join_field| @base_table[base_field].eq(@join_table[join_field]) }
      end

      def conditions_for_table?(table_key)
        @options[:conditions].present? && @options[:conditions][table_key].present?
      end

      def where_clause(table, table_key)
        clauses = @options[:conditions][table_key].map { |key, value| table[key].eq(value) }
        chain_with_method(clauses, :and)
      end

      def chain_with_method(statements, method)
        statements.reduce(nil) do |chained, statement|
          next statement if chained.nil?
          chained.send(method, statement)
        end
      end
    end
  end
end
