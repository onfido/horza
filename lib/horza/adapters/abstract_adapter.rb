module Horza
  module Adapters
    class AbstractAdapter
      extend ::Horza::Adapters::ClassMethods
      include ::Horza::Adapters::InstanceMethods
      extend ActiveSupport::DescendantsTracker

      attr_reader :context

      class << self
        def expected_errors_map
          not_implemented_error
        end

        def entity_context_map
          not_implemented_error
        end
      end

      def get!(id)
        not_implemented_error
      end

      def find_first!(options = {})
        not_implemented_error
      end

      def find_all(options = {})
        not_implemented_error
      end

      def create!(options = {})
        not_implemented_error
      end

      def delete!(id)
        not_implemented_error
      end

      def update!(id, options = {})
        not_implemented_error
      end

      def association(options = {})
        not_implemented_error
      end

      def to_hash
        not_implemented_error
      end

      private

      def collection?
        not_implemented_error
      end
    end
  end
end
