module Graph
  module Solicitud
    class Text  < Component
      attr_accessor :type
      attr_accessor :text
      def initialize(text='')
        @type  = "text"
        @image = text
      end

      def self.json_create(o)
        attrs = JSON.parse(o['data'])
        Solicitud::Language.new(attrs['code'])
      end
    end
  end
end
