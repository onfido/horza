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
    def result
      Class.new(Horza.adapter) do

        def method_missing(method, options = {})
          raise ::Horza::Errors::AdapterNotConfigured.new unless super.respond_to? name
          @context = super.send(method, options, @context)
        end

        def result
          @context
        end
      end
    end
  end
end
