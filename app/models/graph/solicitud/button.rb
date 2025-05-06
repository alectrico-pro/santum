module Graph
  module Solicitud
    class Button
      attr_accessor :subtype
      attr_accessor :index
      attr_accessor :parameters
      def initialize(subtype='', index='', parameters=[])
        @subtype    = subtype
        @index      = index
        @parameters = parameters
      end
      def self.json_create(o)
        attrs = JSON.parse(o['data'])
        ::Graph::Solicitud::Button.new( attrs['subtype'],
                                    attrs['index'],
                                    attrs['parameters'] )
      end
    end
  end
end
