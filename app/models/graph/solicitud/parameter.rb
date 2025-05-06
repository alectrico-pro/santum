module Graph
  module Solicitud
    class Parameter
      include Linea 

      attr_reader :type
      attr_accessor :text
      attr_accessor :image
      attr_accessor :document

      def initialize(type, options={})
        @opciones = options
        @type = type
        case type.to_sym
        when :button
           Graph::Solicitud::Button.new(@opciones)
        when :text
          @text = @opciones
        when :image
          @image =  @opciones
          def self.image 
           Graph::Solicitud::Image.new(@opciones)
          end
        when :document
          def self.document
           Graph::Solicitud::Document.new(@opciones[:link] , @opciones[:filename])
          end
        end

      end

      def self.json_create(o)
        attrs = JSON.parse(o['data'], :quirks_mode => true )
        media = nil
        case attrs['type']
        when 'button'
          unless attrs['button'].nil?
            button_json = {'json_class' => 'Graph::Solicitud::Button',
                                   'data' => attrs['button'].to_json}
            button = Graph::Solicitud::Button.json_create(button_json)
            media = { :subtype => button.subtype, :index => button.index, :parameters => button.parameters }
            return ::Graph::Solicitud::Parameter.new( attrs['type'], media )
          end
        when 'document'
          unless attrs['document'].nil?
            document_json = {'json_class' => 'Graph::Solicitud::Document',
                                   'data' => attrs['document'].to_json}
            document = Graph::Solicitud::Document.json_create(document_json)
            media = { :link => document.link, :filename => document.filename }
            return ::Graph::Solicitud::Parameter.new( attrs['type'], media )
          end

        when 'image'
          unless attrs['image'].nil?
            image_json = {'json_class' => 'Graph::Solicitud::Image',
                        'data'       => attrs['image'].to_json}
             image = Graph::Solicitud::Image.json_create(image_json)
             return ::Graph::Solicitud::Parameter.new( attrs['type'], image.link )
          end

        when 'text'
          unless attrs['text'].nil?
             text_json = {'json_class' => 'Graph::Solicitud::Image',
                        'data'       => attrs['text'].to_json}
             media = attrs['text']
             return ::Graph::Solicitud::Parameter.new( attrs['type'], attrs['text'] )

          end
        end
        
        raise "Not Implemented"

      end
    end
  end
end
