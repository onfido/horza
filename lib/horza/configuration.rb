module Horza
  module Configuration
    String.send(:include, ::Horza::CoreExtensions::String)

    def configuration
      @configuration ||= Config.new
    end

    def reset
      @configuration = Config.new
    end

    def configure
      yield(configuration)
    end
  end

  class Config
    attr_accessor :constant_file_paths

    def initialize
      @constant_file_paths = []
    end

    def clear_constant_file_paths
      constant_file_paths.clear
    end

    def adapter
      @adapter || raise(::Horza::Errors::AdapterError.new("No adapter configured"))
    end

    def adapter=(name)
      @adapter = "Horza::Adapters::#{name.to_s.camelize}".constantize if name
    rescue NameError
      raise ::Horza::Errors::AdapterError.new("No adapter found for: #{name}")
      @adapter = nil
    end
  end
end
