module Horza
  module Configuration 

    def configuration
      @configuration ||= Config.new
    end

    def reset
      @configuration = nil  
    end

    def configure
      yield(configuration)
    end

    [:constant_paths, :clear_constant_paths, :adapter, :adapter=].each do |_meth_|
      define_method(_meth_) do |*args|
        configuration.send(_meth_, *args)
      end
    end


    class Config
      attr_accessor :constant_paths

      def initialize
        @constant_paths = []
      end

      def clear_constant_paths
        constant_paths.clear
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
end
