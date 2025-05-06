module Graph
  class ButtonReply < Graph::Interactive
    attr_accessor :id
    attr_accessor :title

    def initialize( id='', title='')
      #El id se envía asociado al valor de title para poder diferenciarlo
      #Pues este id es el id del presupuesto al que quiero cambiarle el 
      #attributo de comuna
      @id    = id
      @title = title
    end

    def save!
    end

    def procesa( fono, mensaje_id )
      linea.info "Estoy en procesa de Graph::ButtonReply"
      linea.info "Actualizará la comuna del presupuesto"
      id = @id.gsub(@title, '')
      linea.info "id:"
      linea.info id
      presupuesto = ::Electrico::Presupuesto.find_by(:id => id)
      presupuesto.update({:comuna => @title}) if presupuesto.present?
      if presupuesto.present? and presupuesto.comuna and not presupuesto.direccion
        mensaje = "Hemos ingresado la comuna, pero falta que ingrese la dirección de esta forma -> /direccion <<su dirección>>"
        ::Waba::Transaccion.new(:cliente).responder( fono, mensaje_id, mensaje)
      elsif presupuesto.present? and presupuesto.comuna and presupuesto.direccion
        presupuesto.difundir
        mensaje = "Hemos avisado a los colaboradores. Uno de ellos se pondrá en contacto con Ud. en un tiempo prudencial."
        ::Waba::Transaccion.new(:cliente).responder( fono, mensaje_id, mensaje)
      else
        mensaje = "Hemos actualizado la comuna. Revíselo escribiendo /presupuesto"
        ::Waba::Transaccion.new(:cliente).responder( fono, mensaje_id, mensaje)
      end
      return true if presupuesto&.comuna
    end

    def to_json(*a)
      data = {  'id'    => @id,
                'title' => @title      }
      { 'json_class' => self.class.name,
        'data' => data.to_json(*a) }
    end
    
    def self.json_create(o)
      attrs = JSON.parse(o['data'], :quirks_mode => true )
      id    = attrs['id']
      title = attrs['title']
      n = ::Graph::ButtonReply.new(
        id.nil? ? '' : id,  
        title.nil? ? '' : title )
    end

    def monito(msg_id=nil)
      " (button_reply (msg_id #{msg_id}) (id #{@id}))"
    end

    def put
      " (button_reply (id #{@id}))"
    end

  end
end
