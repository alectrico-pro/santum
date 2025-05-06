module Graph
  class Value
    attr_accessor :messaging_product
    attr_accessor :metadata
    attr_accessor :contacts
    attr_accessor :messages
    attr_accessor :statuses

    def initialize(messaging_product='', metadata=nil, contacts=[], messages=[], statuses=[])
      @messaging_product = messaging_product
      @metadata          = metadata
      @contacts          = contacts
      @messages          = messages
      @statuses          = statuses
    end

    def procesa( fono, mensaje_id, publico)
      linea.info "En procesa de value"
      @messages.each {|m| m.procesa(fono, mensaje_id,publico)}
    end

    def save!
    end

    def to_json(*a)
      data = {
               'messaging_product' => @messaging_product,
               'metadata'          => @metadata,
               'contacts'          => @contacts,
               'messages'          => @messages,
               'statuses'          => @statuses  }

      { 'json_create'              => self.class.name,
         'data'                    => data.to_json}
    end

    def self.json_create(o)

      attrs = JSON.parse(o['data'], :quirks_mode => true)

      metadata = nil
      unless attrs['metadata'].nil?
        metadata_json      = {"json_class"=>"Graph::Metadata",
                            'data' => attrs['metadata'].to_json}
        metadata  = ::Graph::Metadata.json_create(metadata_json)
      end

      contacts = attrs['contacts']
      contacts_list = []
      if contacts&.any?
        contacts.each do |contact_data|
          contact_json = {'data' => contact_data.to_json}
          contact = ::Graph::Contact.json_create(contact_json)
          contacts_list << contact
        end
      end

      messages = attrs['messages']
      messages_list = []
      if messages&.any?
        messages.each do |message_data|
          message_json = {'data' => message_data.to_json}
          message = ::Graph::Message.json_create(message_json)
          messages_list << message
        end
      end

      statuses = attrs['statuses']
      status_list = []
      if statuses&.any?
        statuses.each do |status_data|
          status_json = {'data' => status_data.to_json}
          status = ::Graph::Status.json_create(status_json)
          status_list << status
        end
      end

      n=::Graph::Value.new(
                         attrs['messaging_product'],
                         metadata.nil? ? '' : metadata,
                         contacts_list,
                         messages_list,
                         status_list)

    end

    def monito(file_handler=nil, entry_id=nil)
      #raise "entry_id nil" if entry_id.nil?
      raise "file_handler es nil" if file_handler.nil?

      @messages.each do  |i|
        i&.send(:monito, file_handler, entry_id)
      end
      @contacts.each do  |i|
        i&.send(:monito, file_handler, entry_id)
      end
      file_handler.puts @metadata&.send(:monito, entry_id)
      @statuses.each do  |i|
        i&.send(:monito, file_handler, entry_id)
      end

    end

    def put
      fact_format = " (value (messaging_product #{@messaging_product} "
      @contacts.each do  |i|
        contenido =  i&.send(:put)
        unless contenido.blank?
          fact_format += contenido
        end
      end
      contenido = @metadata&.send(:put)
      unless contenido.blank?
         fact_format += contenido
      end
      @messages.each do  |i|
        contenido =  i&.send(:put)
        unless contenido.blank?
          fact_format += contenido
        end
      end
      @statuses.each do  |i|
        contenido =  i&.send(:put)
        unless contenido.blank?
          fact_format += contenido
        end
      end
      fact_format += ' )'
      return fact_format
    end
  end
end
