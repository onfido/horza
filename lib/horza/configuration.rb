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
      @adapter_map ||= generate_map
    end

    private

    def generate_map
      ::Horza::Adapters::AbstractAdapter.descendants.reduce({}) do |hash, (klass)|
        return hash unless klass.name
        hash.merge(klass.name.split('::').last.underscore.to_sym => klass)
      end
    end
  end

  class Config
    attr_accessor :adapter, :development_mode
  end
end
