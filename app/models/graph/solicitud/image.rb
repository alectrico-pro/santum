module Graph
  module Solicitud
    class Image
      attr_accessor :link
      def initialize(link='')
        @link = link
      end
      def self.json_create(o)
        attrs = JSON.parse(o['data'])
        ::Graph::Solicitud::Image.new( attrs['link'] )
      end
    end
  end
end
