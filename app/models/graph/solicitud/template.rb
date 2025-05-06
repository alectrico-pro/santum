module Graph
  module Solicitud
    class Template < Base
      attr_accessor :name
      attr_accessor :language
      attr_accessor :components

      def initialize(name='', language=nil, components=[] )
        @name       = name
        @language   = language
        @components = components
      end

      def self.json_create(o)
        attrs = JSON.parse(o['data'],
                           :quirks_mode => true )

        language=nil
        unless attrs['language'].nil?
          language_json = {'json_class' => 'Graph::Solicitud::Language',
                           'data' => attrs['language'].to_json }
          language      = Graph::Solicitud::Language.json_create(language_json)
        end
    
        components_list = []
        components = attrs['components']
        if components&.any?
          components.each do |component_data|
            component_json = {'json_class' => '::Graph::Solicitud::Component',
                              'data' => component_data.to_json}
            component = ::Graph::Solicitud::Component.json_create( component_json )
            components_list << component
          end
        end

        ::Graph::Solicitud::Template.new(
          attrs['name'], 
          language.nil? ? '' : language,
          components_list        )
      end

      def put( parent_id=nil)
        raise "parent_id is nil on put ::Graph::Solicitud::Template" if parent_id.nil?
        "(template (parent_id #{parend_id}) (name #{@name}) (language #{@language}))"         
      end

      def monito( redisfile=nil, parent_id=nil)
        raise "parent_id is nil on put ::Graph::Solicitud::Template" if parent_id.nil?
        raise "redisfile is nil on put ::Graph::Solicitud::Template" if redisfile.nil?
        redisfile << "(template (parent_id #{parent_id}) (name #{@name}) (language #{@language.code}))"
      end
    end
  end
end
