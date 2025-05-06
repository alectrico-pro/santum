module Graph
  module Solicitud
    class Text 
      attr_accessor :text
      def initialize( text='' )
        @text = text
      end
      def self.json_create(o)
        #inea.info "Json. crate en Graph::Solicitud::Text"
        #inea.info o
        #ttrs = JSON.parse(o['data'])
        #inea.info attrs
        ::Graph::Solicitud::Text.new(o['data'] )
      end
    end
  end
end
