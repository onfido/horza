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

    class RecordInvalid < StandardError
    end

    class RecordNotFound < StandardError
    end

    class InvalidOption < StandardError
    end
  end
end
