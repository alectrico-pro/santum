module Graph
  class Status
    attr_accessor :id
    attr_accessor :status
    attr_accessor :timestamp
    attr_accessor :recipient_id
    attr_accessor :conversation
    attr_accessor :pricing
    attr_accessor :errors

    def initialize( id='', status='', timestamp='', recipient_id='', conversation=nil, pricing=nil, errors=nil)
      @id           = id
      @status       = status
      @timestamp    = timestamp
      @recipient_id = recipient_id
      @conversation = conversation
      @pricing      = pricing
      @errors       = errors
    end

    def save!
    end

    def to_json(*a)
      data = {        'id' => @id,
                  'status' => @status,
               'timestamp' => @timestamp,
            'recipient_id' => @recipient_id, 
            'conversation' => @conversation,
            'pricing'      => @pricing,
            'errors'       => @errors
             }
      { 'json_class' => self.class.name,
        'data' => data.to_json(*a) }
    end

    def self.json_create(o)
      attrs = JSON.parse(o['data'], :quirks_mode => true )

      conversation = nil
      unless attrs['conversation'].nil?
        conversation_json = {'json_create' => 'Graph::Conversation',
                          'data' => attrs['conversation'].to_json}
        conversation = ::Graph::Conversation.json_create(conversation_json)
      end

      pricing = nil
      unless attrs['pricing'].nil?
        pricing_json = { "json_class" => "Graph::Pricing",
                    'data' => attrs['pricing'].to_json}
        pricing = ::Graph::Pricing.json_create(pricing_json)
      end

      errors = attrs['errors']
      errors_list = []
      if  errors&.any?
        errors.each do |error_data|
          error_json = { 'data' => error_data.to_json }
          error = ::Graph::Error.json_create( error_json )
          errors_list << error
        end
      end


      n = ::Graph::Status.new(attrs['id'],
                              attrs['status'],
                              attrs['timestamp'],
                              attrs['recipient_id'],
                              conversation,
                              pricing,
                              errors_list 
                             )
    end

#      @errors.each do |i|
#         i&.send(:monito,file_handler, @id )
#      end

    #wip
    def procesa
      linea.info "En Graph::Status.procesa"
      linea.info "Nada se hace por ahora"
      linea.info "Interesante si se pudiera procesar el error de no pago: 131042 haciendo un push"
    end

    def monito(file_handler=nil, entry_id=nil)
      raise "file_handler es nil en monito de status" if file_handler.nil?
      raise "entry_id es nil en monito de status" if entry_id.nil?
      file_handler.puts  " (status (status #{@status} ) (id #{@id} ) (entry_id #{entry_id}) (timestamp #{@timestamp}) (recipient_id #{@recipient_id}))"
      file_handler.puts  @conversation&.send(:monito, @id, file_handler)
      file_handler.puts  @pricing&.send(:monito, @id)
      @errors.each do |i|
        file_handler.puts i&.send(:put, @id)
      end
    end


    def put
      fact_format =  " (status (status #{@status} ) (id #{@id} ) (timestamp #{@timestamp}) (recipient_id #{@recipient_id})"
      contenido =  @conversation&.send(:put)
      unless contenido.blank?
        fact_format += contenido
      end
      contenido =  @pricing&.send(:put)
      unless contenido.blank?
        fact_format += contenido
      end
      @errors.each do |i|
        contenido = i&.send(:put, @id)
        unless contenido.blank?
          fact_format += contenido
        end
      end

      fact_format += " )"
      return fact_format
    end

  end
end
