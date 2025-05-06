module Graph
  module Solicitud
    class Header
      attr_accessor :type
      attr_accessor :parameters
      def initialize(type='', parameters=[] )
        @type=type
        @parameters=parameters
      end
    end
  end
end
