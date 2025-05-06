module Graph
  class Entry
    attr_accessor :id
    attr_accessor :changes

    def initialize(id='WHATSAPP_BUSINESS_ACCOUNT_ID', changes=[] )
      @id      = id
      @changes = changes
    end

    def procesa( fono, mensaje_id, publico)
      linea.info "En procesa de entry"
      @changes.each {|c| c.procesa(fono, mensaje_id, publico)}
    end

    def save!
    end

    def to_json(*a)
      data= { 'id'    => @id,
            'changes' => @changes }
      { 'json_class'  => self.class.name,
              'data'  => data.to_json(*a)  }
    end 

    def self.json_create(o)
      attrs=JSON.parse(o['data'], :quirks_mode => true )

      changes = attrs['changes']
      changes_list = []
      if changes&.any?
        changes.each do |change_data|
          change_json = {'data' => change_data.to_json}
          change = ::Graph::Change.json_create(change_json)
          changes_list << change
        end
      end
      n=::Graph::Entry.new(attrs['id'], changes_list)
    end

    def monito(object, file_handler=nil)
      raise "file_handler es nil" if file_handler.nil?
      #raise "id es nil en entry" if @id.nil?
      file_handler << " (entry (id #{@id}) (object #{object})  ) "
      @changes.each do |i|
        i&.send(:monito, file_handler, @id)
      end

    end


    def put
      fact_format = " (entry (id #{@id} )"
      @changes.each do |i|
        contenido = i.send(:put) 
        unless contenido.blank?
          fact_format += contenido
        end 
      end
      fact_format += ' )'
      return fact_format
    end

  end
end
