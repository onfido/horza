require 'active_model/naming'
require 'active_model/validations'
require 'active_model/conversion'

module Horza
  module Entities
    class SingleWithActiveModel < Single
      include ActiveModel::Validations
      include ActiveModel::Conversion
      extend ActiveModel::Naming

      def persisted?
        false
      end
    end
  end
end
