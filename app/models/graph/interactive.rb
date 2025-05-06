module Graph
  class Interactive < Graph::Message
    attr_accessor :type
    attr_accessor :button_reply
    attr_accessor :list_reply
    attr_accessor :nfm_reply

    def initialize( type='', button_reply=nil, list_reply=nil, nfm_reply=nil )
      @type         = type
      @button_reply = button_reply 
      @list_reply   = list_reply
      @nfm_reply    = nfm_reply
    end

    def save!
    end

    def procesa( fono, mensaje_id, publico )
      linea.info "En procesa de Interactive"
      @button_reply&.procesa( fono, mensaje_id )
      @list_reply&.procesa( fono, mensaje_id, publico)
      @nfm_reply&.procesa( fono, mensaje_id, publico)
    end

    def to_json(*a)
      data = {  'type'         => @type,
                'button_reply' => @button_reply,
                'list_reply'   => @list_reply,
                'nfm_reply'   => @nfm_reply
      }
      { 'json_class' => self.class.name,
        'data' => data.to_json(*a) }
    end
   
    def self.json_create(o)
      attrs = JSON.parse(o['data'], :quirks_mode => true )
      type          = attrs['type']

      unless attrs['button_reply'].nil?
        button_reply_json = {"json_class" => "Graph::ButtonReply",
                        'data'       => attrs['button_reply'].to_json}
        button_reply = ::Graph::ButtonReply.json_create(button_reply_json)
      end
      unless attrs['list_reply'].nil?
        list_reply_json = {"json_class" => "Graph::ListReply",
                        'data'       => attrs['list_reply'].to_json}
        list_reply = ::Graph::ListReply.json_create(list_reply_json)
      end
      unless attrs['nfm_reply'].nil?
        nfm_reply_json = {"json_class" => "Graph::NfmReply",
                        'data'       => attrs['nfm_reply'].to_json}
        nfm_reply = ::Graph::NfmReply.json_create(nfm_reply_json)
      end

      n = ::Graph::Interactive.new(
        type.nil? ? '' : type,  
        button_reply,
        list_reply,
        nfm_reply
      )
    end

    def monito(file_handler=nil, msg_id=nil)
      raise "msg_id is nil on Graph::Interactive" if msg_id.nil?
      raise "file_handler is nil on Graph::Interactive" if file_handler.nil?

      fact_format = " (interactive (type #{@type})"
    
      unless msg_id.nil?
        fact_format += " (msg_id #{msg_id}) "
      end
      file_handler.puts @button_reply&.monito(msg_id )

      file_handler.puts @nfm_reply&.monito(msg_id )

      #unless contenido.blank?
      #  fact_format += contenido
      #end
      fact_format += " )"
    end


    def put(msg_id=nil)
      raise "msg_id is nil on Graph::Interactive.put" if msg_id.nil?

      fact_format = " (interactive (type #{@type})"
      unless msg_id.nil?
        fact_format += " (msg_id #{msg_id}) "
      end
      contenido = @button_reply&.send(:put)
      unless contenido.blank?
        fact_format += contenido
      end
      contenido = @nfm_reply&.send(:put)
      unless contenido.blank?
        fact_format += contenido
      end

      fact_format += " )"
    end

  end
end
