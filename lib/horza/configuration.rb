module Horza
  module Configuration
    String.send(:include, ::Horza::CoreExtensions::String)

    def configuration
      @configuration ||= Config.new
    end

    def reset
      @configuration = Config.new
      @adapter, @adapter_map = nil, nil # Class-level cache clear
    end

    def configure
      yield(configuration)
    end

    def adapter
      raise ::Horza::Errors::AdapterNotConfigured.new unless configuration.adapter
      @adapter ||= adapter_map[configuration.adapter]
    end

    def adapter_map
      @adapter_map ||= ::Horza.descendants_map(::Horza::Adapters::AbstractAdapter)
    end
  end

  class Config
    attr_accessor :adapter, :constant_file_paths

    def initialize
      @constant_file_paths = []
    end

    def clear_constant_file_paths
      constant_file_paths.clear
    end
  end
end
