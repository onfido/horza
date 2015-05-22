module Horza
  module Errors
    class AdapterNotConfigured < StandardError
    end

    class MethodNotImplemented < StandardError
    end

    class InvalidAncestry < StandardError
    end

    class QueryNotYetPerformed < StandardError
    end

    class CannotGetHashFromCollection < StandardError
    end
  end
end
