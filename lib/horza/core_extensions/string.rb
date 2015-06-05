module Horza
  module CoreExtensions
    module String
      def singular?
        singularize(:en) == self
      end

      def plural?
        pluralize(:en) == self
      end

      def symbolize
        underscore.to_sym
      end

      def underscore
        gsub(/::/, '/')
        .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
        .gsub(/([a-z\d])([A-Z])/, '\1_\2')
        .tr('-', '_')
        .downcase
      end
    end
  end
end
