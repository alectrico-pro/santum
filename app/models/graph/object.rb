module Graph
  class Object
    #descripcion al estilo sequen...org
    attr_accessor :uml 
    attr_accessor :object
    attr_accessor :entry

    def initialize(object='whastapp_business_account', entry=[] )
      @object = object
      @entry  = entry
    end

    def procesa( fono, mensaje_id, publico)
      linea.info "En procesa de Graph::Object"
      @entry.each {|e| e.procesa(fono, mensaje_id, publico)}
    end

  #usar un indicador de tipo mejor
   def tipo
      #linea.info entry.first.changes.first.value.inspect
     #entry.first.changes.first.value.messages.first.nil? ? 
     #entry.first.changes.first.value.statuses.first.status :
    # entry.first.changes.first.value.messages.first.type
      nil
    end

    def es_para_mi?
      #self.entry.first.id.to_i == WabaCfg.waba_id and \
      #self.entry.first.changes.first.value.metadata.phone_number_id.to_i ==  WabaCfg.phone_id 
      return true
    end

    def get_message
      #El mensaje puede ser un texto String o un objeto TEXT que tiene body
      if entry.first.changes.first.value.messages.first.text.body.nil? ? '' : entry.first.changes.first.value.messages.first.text.respond_to?(:body)

        entry.first.changes.first.value.messages.first.text.body.nil? ? '' : entry.first.changes.first.value.messages.first.text.body 

      elsif entry.first.changes.first.value.messages.first.text.body.nil? ? '' : entry.first.changes.first.value.messages.first.respond_to?(:text)

        entry.first.changes.first.value.messages.first.text
      end
    end

    def from
      if entry and entry.any?
        entry.first.changes.first.value.messages.first.nil? ? '' : entry.first.changes.first.value.messages.first.from
      else
        ''
      end
    end

    #id puede provenir de los status o de los mensajes
    def id
      entry.first.changes.first.value.statuses.first.nil? ? '' :
      (return  entry.first.changes.first.value.statuses.first.id )
      entry.first.changes.first.value.messages.first.nil? ? '' :
      (return entry.first.changes.first.value.messages.first.id )
    end

    def payload
      begin
        entry.first.changes.first.value.messages.first.send  entry.first.changes.first.value.messages.first.type.to_sym
      rescue StandardError => e
        begin
          entry.first.changes.first.value&.statuses.first&.status
        rescue StandardError => e
          linea.error e.message
        end
      end
    end

    def to
      if entry and entry.any?
        entry.first.changes.first.value.statuses.first.nil? ? '' :
        (return  entry.first.changes.first.value.statuses.first.recipient_id )
        entry.first.changes.first.value.metadata.display_phone_number
      else
        ''
      end
    end

   #def recipiente
   #  entry.first.changes.first.value&.status.recipient_id
   #end

    def save!
    end

    def to_json(*a)
      data= { 'object' => @object,
              'entry'  => @entry }
      {  'json_class'  => self.class.name,
               'data'  => data.to_json(*a)  }
    end 

    def self.json_create(o)
      attrs=JSON.parse(o['data'], :quirks_mode => true )
      entries = attrs['entry']
      entries_list = []
      if entries&.any?
         entries.each do |entry_data|
           entry_json = { 'data' => entry_data.to_json }
           entry = ::Graph::Entry.json_create(entry_json)
           entries_list << entry
        end
      end
      n=::Graph::Object.new(attrs['object'], entries_list)
    end


    def monito(file_handler)
      @entry.each do |i|
        i&.send(:monito, @object, file_handler)
      end
    end

    def put
      fact_format = "( ob (objt #{@object})"
      @entry.each do |i|
        contenido =  i&.send(:put)
        unless contenido.blank?
          fact_format = fact_format + contenido
        end
      end
      fact_format = fact_format + ' )'
      return fact_format
    end
  end

end
