require 'hashie'

module Horza
  module Entities
    class Single < Hash
      include Hashie::Extensions::MethodAccess

      def initialize(attributes)
        update(attributes)
      end

      # Some libraries (ie. ActiveModel serializer) use their own methods to access attributes
      # These are aliased to the generic_getter
      def generic_getter(name)
        send(name)
      end

      alias_method :read_attribute_for_serialization, :generic_getter
    end
  end
end
