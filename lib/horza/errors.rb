module Horza
  module Errors
    class AdapterNotConfigured < StandardError
    end

    class MethodNotImplemented < StandardError
    end

    class InvalidAncestry < StandardError
    end
  end
end
