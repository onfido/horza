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
    attr_accessor :adapter, :development_mode, :namespaces

    def namespaces
      return @namespaces || []
    end
  end
end
