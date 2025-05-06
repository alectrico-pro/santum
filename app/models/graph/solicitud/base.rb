#No realizaco por falta de presupeusto
#Se usa una versión simplificada en Waba Trnsacción
module Graph
  module Solicitud
    class Graph::Solicitud::Base
      attr_accessor :messaging_product
      attr_accessor :to
      attr_accessor :type
      attr_accessor :template
      attr_accessor :recipient_type
      attr_accessor :document
      attr_accessor :text
      attr_accessor :interactive
      #se usa pero no en initiaze
      attr_accessor :id

      #id se obtiene solo al enviar la solicitud en Waba::Transaccion
      #entonces solo generar este fact si se tiene la id
      #no tienen sentido generarla si no se envío con éxito
      attr_accessor :id

      def set_id( id)
        @id = id
      end

      def initialize(messaging_product='', to='', type='', template=nil, recipient_type='', document=nil, text='', interactive= nil, id=0)
        @messaging_product = messaging_product
        @to                = to
        @type              = type
        @template          = template
        @recipient_type    = recipient_type
        @document          = document
        @text              = text
        @interactive       = interactive
        @id                = id
      end

      def to_json(*a)
         puts "En to_json de solicitud"
          data= {
            'messaging_product' => @messaging_product,
                           'to' => @to,
                         'type' => @type,
                     'template' => @template,
               'recipient_type' => @recipient_type,
                     'document' => @document,
                         'text' => @text,
                  'interactive' => @interactive,
                  'id'          => @id
          }
        {  'json_class'  => self.class.name,
                 'data'  => data.to_json(*a)  }
      end

      def self.json_create(o)
        attrs = JSON.parse(o['data'], :quirks_mode => true )


        template = nil
        unless attrs['template'].nil?
          template_json ={'json_class' => 'Graph::Solicitud::Template' ,
                          'data' => attrs['template'].to_json }
          template = Graph::Solicitud::Template.json_create(template_json)
        end

        document = nil
        unless attrs['document'].nil?
          document_json ={'json_class' => 'Graph::Solicitud::Document' ,
                          'data' => attrs['document'].to_json }
          document = Graph::Solicitud::Document.json_create(document_json)
        end

        interactive = nil
        unless attrs['interactive'].nil?
          interactive_json ={'json_class' => 'Graph::Interactive' ,
                          'data' => attrs['interactive'].to_json }
          interactive = Graph::Interactive.json_create(interactive_json)
        end


        n = ::Graph::Solicitud::Base.new(
                             attrs['messaging_product'], 
                             attrs['to'],
                             attrs['type'],
                             template,
                             attrs['recipient_type'],
                             document,
                             attrs['text'],
                             interactive,
                             attrs['id'] )
        return n
      end


      def put( id )
        fact_format = "(solicitud (id #{@id}) (messaging_product #{@messaging_product} ) (to #{@to} ) (type #{@type} ) (template #{@template} {recipient_type #{@recipient_type}) (text #{@text} )"
        contenido =  @document&.send(:put)
        unless contenido.blank?
          fact_format = fact_format + contenido
        end
        fact_format = fact_format + ' )'
        return fact_format
      end


      def monito( redisfile=nil )
        linea.info "En monito de Graph::Solicitud::Base"
        raise "Redisfile is nil on Monito de Graph::Solicitud::Base" if redisfile.nil?
        fact_format = "(solicitud (id #{@id}) (messaging_product #{@messaging_product} ) (to #{@to} ) (type #{@type}) "
        unless @recipient_type.blank?
          fact_format += "(recipient_type #{@recipient_type})"
        end
        @document&.send(:monito, redisfile)
        @interactive&.send(:monito, redisfile, id)
        @template&.send(:monito, redisfile, id)
        fact_format = fact_format + ' )'
        redisfile << fact_format 
      end

    end
  end
end
