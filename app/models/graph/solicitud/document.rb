module Graph
  module Solicitud
    class Document
      attr_accessor :link
      attr_accessor :filename

      def initialize(link='', filename='')
        @link = link
        @filename = filename
      end

      def self.json_create(o)
        attrs = JSON.parse(o['data'])
        Graph::Solicitud::Document.new( attrs['link'], attrs['filename'] )
      end

      def put( solicitud_id=nil )
        raise "solicitud_id is nil" if solicitud_id.nil?
        "(document (solicitud_id #{solicitud_id}) (link #{@link} (filename #{@filename}) ) )"
      end

      def monito(  solicitud_id=nil,  redisfile=nil)
        raise "redisfile is nil on monito Graph::Solicitud::Document" if redisfile.nil?
        raise "solicitud_id is nil on monito Graph::Solicitud::Document" if solicitud_id.nil?
        redisfile << "(document (solicitud_id #{solicitud_id}) (link #{@link} (filename #{@filename}) ) )"
      end
    end
  end
end
