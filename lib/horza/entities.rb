module Horza
  module Entities
    class << self
      def const_missing(name)
        parent_klass = name.to_s.plural? ? Horza::Entities::Collection : Horza::Entities::Single
        Horza::Entities.const_set(name, Class.new(parent_klass))
      end
    end
  end
end
