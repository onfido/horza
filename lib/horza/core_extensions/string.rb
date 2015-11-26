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
    end
  end
end

String.send(:include, ::Horza::CoreExtensions::String)