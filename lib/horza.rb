require 'active_support/inflections'
require 'active_support/descendants_tracker'
require 'active_support/core_ext/module/delegation'
require 'active_support/dependencies'
require 'horza/dependency_loading'
require 'horza/adapters/class_methods'
require 'horza/adapters/instance_methods'
require 'horza/adapters/options'
require 'horza/adapters/abstract_adapter'
require 'horza/adapters/active_record/active_record'
require 'horza/adapters/active_record/arel_join'
require 'horza/core_extensions/string'
require 'horza/entities/single'
require 'horza/entities/collection'
require 'horza/entities/single_with_active_model'
require 'horza/entities'
require 'horza/configuration'
require 'horza/errors'


module Horza
  extend Configuration

  class << self
    delegate :constant_file_paths, :clear_constant_file_paths, :constant_file_paths=, :adapter,  to: :configuration
    
    def descendants_map(klass)
      klass.descendants.reduce({}) { |hash, (klass)| hash.merge(klass.name.split('::').last.underscore.to_sym => klass) }
    end

    def adapt(klass)
      adapter.new(klass)
    end

    def single(params = {})
      Horza::Entities::Single.new(params)
    end

    def collection(items = [])
      Horza::Entities::Collection.new(items)
    end
  end
end
