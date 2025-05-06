module Graph
  class ListReply < Graph::Interactive
    attr_accessor :id
    attr_accessor :title
    attr_accessor :description
    def initialize( id='', title='', description='')
      #El id se envía asociado al valor de title para poder diferenciarlo
      #Pues este id es el id del presupuesto al que quiero cambiarle el 
      #attributo de comuna
      @id          = id
      @title       = title
      @description = description
    end

    def save!
    end

    def procesa( fono, mensaje_id, publico)
      linea.info "Estoy en procesa de Graph::ListReply"
      linea.info "id:"
      linea.info id
      #presupuesto = ::Electrico::Presupuesto.find_by(:id => id)
      case @title
      when "Problema reportado:"
        mensaje = "Comience escribiendo /descripcion y a continuación la descripción del problema. Ejemplo: /descripcion No tengo luz en el living."
        ::Waba::Transaccion.new(publico).responder( fono, mensaje_id, mensaje)
      when "Email del Usuario:"
        mensaje = "Comience escribiendo /email y a continuación su email. Ejemplo: /email ventas@alectrico.cl."
        ::Waba::Transaccion.new(publico).responder( fono, mensaje_id, mensaje)
      when "Ubicación:"
        mensaje = "Comience escribiendo /direccion y a continuación su dirección. Ejemplo: /direccion Bilbao 2999 Dpto 23. Providencia."
       ::Waba::Transaccion.new(publico).responder( fono, mensaje_id, mensaje)
      else
        mensaje = "#{@title} no se puede modificar."
        ::Waba::Transaccion.new(publico).responder( fono, mensaje_id, mensaje)
      end
    end

    def to_json(*a)
      data = {  'id'          => @id,
                'title'       => @title,
                'description' => @description  }
      { 'json_class' => self.class.name,
        'data' => data.to_json(*a) }
    end
    
    def self.json_create(o)
      attrs       = JSON.parse(o['data'], :quirks_mode => true )
      id          = attrs['id']
      title       = attrs['title']
      description = attrs['description']

      n = ::Graph::ListReply.new(
        id,  
        title,
        description  )
    end

    def monito(msg_id=nil)
      " (list_reply (msg_id #{msg_id}) (id #{@id}))"
    end

    def put
      " (list_reply (id #{@id}))"
    end

  end
end
