module Graph
  class Change
    attr_accessor :value
    attr_accessor :field

    def initialize(value=nil,field="messages")
      @value         = value
      @field         = field
    end

    def procesa( fono, mensaje_id, publico)
      linea.info "En procesa de change"
      @value.procesa( fono, mensaje_id, publico)
    end

    def save!
    end

    def to_json(*a)
      data = { 'value'          => @value, 
               'field'          => @field }
      { 'json_create'           => self.class.name,
         'data'                 => data.to_json}
    end

    def self.json_create(o)
      attrs = JSON.parse(o['data'], :quirks_mode => true)
      value_json         = {"json_class"=>"Graph::Value",
                            'data' => attrs['value'].to_json}
      value     = ::Graph::Value.json_create(value_json)
      n=::Graph::Change.new(
        value, 
        attrs['field']
      )
    end

    def monito( file_handler, entry_id )
      file_handler.puts " (change (field #{@field}) (entry_id #{entry_id}) )"
      @value&.send(:monito, file_handler, entry_id)
    end


    def put
      fact_format = ' (change '
      contenido = @value&.send(:put)
      unless contenido.blank?
        fact_format += contenido
      end
      fact_format += ' )'
      return fact_format
    end
  end
end
