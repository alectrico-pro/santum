#no genera fact_format
#hay que trabajarlo
module Graph
  class Button < Graph::Message

    attr_accessor :payload
    attr_accessor :text

    def initialize(payload=nil, text='')
      @payload = payload
      @text    = text
    end

    def save!
    end

    def procesa( fono, mensaje_id, publico )
      linea.info "Estoy en procesa de Graph::Button"
      @payload.procesa( fono, mensaje_id, publico )
    end

    def to_json(*a)
      data = { 'payload' => @payload,
               'text'    => @text   }
      { 'json_class' => self.class.name,
        'data' => data.to_json(*a) }
    end
    
    def self.json_create(o)
      attrs = JSON.parse(o['data'], :quirks_mode => true )

      unless attrs['payload'].nil?
        payload_json = {"json_class" => "Graph::Payload",
                        'data'       => attrs['payload'].to_json}
        payload = ::Graph::Payload.json_create(payload_json)
      end
      text    = attrs['text']
      n = ::Graph::Button.new(
        payload,
        attrs['text']  )
    end

    def monito( file_handler=nil, msg_id=nil)
      raise "msg_id es nil" if msg_id.nil?
      raise "file_handler es nil" if file_handler.nil?

      fact_format = ' (button '
      fact_format += "(msg_id #{msg_id}) "
      file_handler.puts @payload&.send(:monito)

      unless @text.blank?
        fact_format += " ( text #{@text.parameterize})"
      end
      fact_format += ' )'
    end

    def put(message_id=nil)
      
      fact_format = ' (button '
      unless message_id.nil?
        fact_format += "(message_id #{message_id}) "
      end
      contenido = @payload&.send(:put)
      unless contenido.blank?
        fact_format += contenido
      end
      unless @text.blank?
        fact_format += " ( text #{@text})"
      end
      fact_format += ' )'
    end
  end
end
