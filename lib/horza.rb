require 'horza/adapters/abstract_adapter'
require 'horza/adapters/active_record'
require 'horza/core_extensions/string'
require 'horza/entities/single'
require 'horza/entities/collection'
require 'horza/entities'
require 'horza/configuration'
require 'horza/errors'
require 'active_support/inflector'

module Horza
  extend Configuration

  class << self
    def descendants_map(klass)
      klass.descendants.reduce({}) { |hash, (klass)| hash.merge(klass.name.split('::').last.underscore.to_sym => klass) }
    end
  end
end
