module Graph
  class NfmReply < Graph::Interactive
    attr_accessor :response_json
    attr_accessor :body
    attr_accessor :name

    include CrearUsuario

    def initialize( response_json={}, body='Sent', name='flow')
      #El id se envía asociado al valor de title para poder diferenciarlo
      #Pues este id es el id del presupuesto al que quiero cambiarle el 
      #attributo de comuna
      @response_json  = response_json
      @body           = body
      @name           = name
    end

    def save!
    end

    #este es un caso probable de un conserje que crea un presupuesto
    #para otro

    def procesa_comercio(fono_conserje, mensaje_id, publico, presupuesto )

      linea.info "Fue encontrado presupuesto en procesa_comercio de NfmReply" if presupuesto


      json = JSON.parse(@response_json).with_indifferent_access

      email        = json[:email]
      nombre       = json[:nombre]
      apellido     = json[:apellido]
      sintomas     = json[:sintomas]
      descripcion  = json[:descripcion]
      direccion    = json[:direccion]
      comuna       = json[:comuna]
      fono         = json[:fono]

      linea.info "email:"
      linea.info email
      linea.info "nombre"
      linea.info nombre
      linea.info "apellido"
      linea.info apellido
      linea.info "fono"
      linea.info fono
      linea.info "descripcion"
      linea.info descripcion
      linea.info "comuna"
      linea.info comuna

      linea.info "Síntomas"
      linea.info sintomas.inspect

      presupuesto_descripcion = presupuesto.descripcion

      if sintomas.any?
        presupuesto.descripcion = ""
        linea.info "Síntomas"
        sintomas.each do |sintoma|
          linea.info sintoma
          case sintoma
          when "0"
            texto_sintoma="Transferir a Cuenta En USD"
          when "1"
            texto_sintoma="Transferir a Cuenta en CUP"
          when "2"
            texto_sintoma="Tarjeta de Crédito Mastercard"
          when "3"
            texto_sintoma="Tarjeta de Crédito Visa"
          when "4"
            texto_sintoma="Efectivo USD"
          when "5"
            texto_sintoma="Efectivo MLC"
          end

          presupuesto_descripcion = "#{presupuesto_descripcion} | #{texto_sintoma}"
          linea.info presupuesto_descripcion
        end
      else
        linea.info "No hay síntomas"
      end
      usuario = crear_usuario( fono, nombre, email )

      rendicion =  ::Operacion::Rendicion.find_by(:presupuesto_id => presupuesto.id)

      if rendicion.present?
        presupuesto.update({:efimero => false, :vigente => false})
      else
        presupuesto.destroy
      end



      presupuesto_nuevo = ::Electrico::Presupuesto.create(
         {:usuario => usuario,
          :es_comercio => true,
          :es_electricidad => false,
          :descripcion => presupuesto_descripcion,
          :direccion => direccion,
          :comuna => comuna,
          :efimero => true,
          :fono => fono})

      if presupuesto_nuevo.present?
     #   mensaje = "Se ha creado un presupuesto nuevo en procesa comercio #{presupuesto_nuevo.inspect}"
      #  ::Waba::Transaccion.new(:cliente).responder( fono, mensaje_id, mensaje)
      end

      if sintomas.any?
        sintomas.each do |sintoma|
          case sintoma
          when "0"
            texto_sintoma="Transferir a Cuenta En USD"
            #presupuesto_nuevo.update(:reparar => true)
          when "1"
            texto_sintoma="Transferir a Cuetna en CUP"
            #presupuesto_nuevo.update(:reparar => true)
          when "2"
            texto_sintoma="Tarjeta de Crédito Mastercard"
            #presupuesto_nuevo.update(:instalar => true)
          when "3"
            texto_sintoma="Tarjeta de Crédito Visa"
            #presupuesto_nuevo.update(:certificar => true)
          when "4"
            texto_sintoma="Efectivo USD"
            #presupuesto_nuevo.update(:ampliar => true)
          when "5"
            texto_sintoma="Efectivo CUP"
            #presupuesto_nuevo.update(:reparar => true)
            #
          when "6"
            texto_sintoma="Efectivo MLC"
            #presupuesto_nuevo.update(:reparar => true)
          end
        end
      end

      presupuesto_nuevo.comunicar

      conserje = ::User.find_by(:fono => fono_conserje)
      if fono != fono_conserje
        mensaje = "#{conserje.name}, estamos solicitando el pago a otra persona. No considere los links de pagos que le hemos envíado a Ud."
        ::Waba::Transaccion.new(:cliente).responder( fono_conserje, mensaje_id, mensaje)
        ::Waba::Transaccion.new(:cliente).enviar_confirmar_fono( presupuesto_nuevo)
        mensaje = "Hola, #{conserje.name} ha solicitado una visita a domicilio en alectrico®, a ser efectuada en su nombre, ahora puede pagar la visita siguiendo el link:"
        ::Waba::Transaccion.new(:cliente).responder( fono, mensaje_id, mensaje)
        auth_token = ::Waba::Transaccion.new(:admin).autoriza( presupuesto_nuevo.usuario)
        url_de_pago="#{C.api_url}/api/v1/electrico/presupuestos/#{presupuesto_nuevo.remember_token}/pagar_oferta/?auth_token=#{auth_token}"
        ::Waba::Transaccion.new(:cliente).enviar_url(fono, url_de_pago)

        mensaje = "Si no conoce a #{conserje.name}, fono: #{conserje.fono}, ignore este mensaje por favor y escríbanos a alectrico@outlook.cl informando el fono para que podamos bloquearlo"
        ::Waba::Transaccion.new(:cliente).responder( fono, mensaje_id, mensaje)
        mensaje = "En el chat escriba /presupuesto para revisar los datos de la atención. Puede corregir su email digitando /email, su dirección digitando /direccion, la descripción del problema con /descripcion. Tambíen puede conocer nuestros precios digitando /catalogo. Por último puede obtener un diagrama para su tablero eléctrico digitando /unilineal"
        ::Waba::Transaccion.new(:cliente).responder( fono, mensaje_id, mensaje)
        mensaje = "Por favor llame para que le confirmen la recepción en el WhatsApp del fono que Ud. informó"
        ::Waba::Transaccion.new(:cliente).say_mensaje_de_exito( presupuesto_nuevo, conserje, mensaje )
      else
        mensaje = "Fantástico, ya puede comprar con los catálogos."
        ::Waba::Transaccion.new(:cliente).say_mensaje_de_exito( presupuesto_nuevo, conserje, mensaje )
        enviar_catálogos( fono)
      end
    end

    def enviar_catálogos( fono )
      ::Waba::Transaccion.new(:cliente).enviar_catalogo_de_productos(fono, :en_dolar)
   #      ::Waba::Transaccion.new(:cliente).enviar_catalogo_de_productos(fono, :en_mlc)
      ::Waba::Transaccion.new(:cliente).enviar_catalogo_de_productos(fono, :en_cup)
    end


    def procesa( fono_conserje, mensaje_id, publico)
      linea.info "Estoy en procesa de Graph::NfmtReply"
      linea.info "Response_json es:"
      linea.info @response_json.inspect

      json = JSON.parse(@response_json).with_indifferent_access
   #  {"response_json"=>"{\"flow_token\":\"193\",\"email\":\"idkd@l.com\",\"lastName\":\"odkdo\",\"firstName\":\"lxlzl\",\"source\":\"1\"}"
      #[35m"{\"flow_token\":\"223\",\"comuna\":\"Las_Condes\",\"sintomas\":\"\#{data.sintomas}\",\"email\":\"yhj@hhhh.com\",\"fono\":\"56993951576\",\"apellido\":\"kdldl\",\"direccion\":\"jsjsk\",\"nombre\":\"idlsl\",\"descripcion\":\"kzksksll\",\"fecha\":\"${form.fecha}\"}"[0m

#      [13/mar/2024:02:51:09] ip-172-26-76-136.ec2.internal [32mINFO[0m [36mGraph::NfmReply[0m [35m"{\"flow_token\":\"228\",\"comuna\":\"Ñuñoa\",\"sintomas\":[\"0\",\"2\"],\"email\":\"ksksl@bsksk.com\",\"fono\":\"569646466\",\"apellido\":\"isksl\",\"direccion\":\"ksksk\",\"nombre\":\"mzmzm\",\"descripcion\":\"mzmzm\",\"fecha\":\"1710298254692\"}
      presupuesto_id = json[:flow_token]
      presupuesto = ::Electrico::Presupuesto.find_by(:id => presupuesto_id)
      if presupuesto.es_comercio
        procesa_comercio( fono_conserje, mensaje_id, publico, presupuesto )
      elsif presupuesto.es_electricidad
        procesa_electricidad( fono_conserje, mensaje_id, publico, presupuesto )
      end
    end

    def procesa_electricidad(fono_conserje, mensaje_id, publico, presupuesto )

      linea.info "Fue encontrado presupuesto en procesa_electricidad de NfmReply" if presupuesto
      json = JSON.parse(@response_json).with_indifferent_access

      email        = json[:email]
      nombre       = json[:nombre]
      apellido     = json[:apellido]
      sintomas     = json[:sintomas]
      descripcion  = json[:descripcion]
      direccion    = json[:direccion]
      comuna       = json[:comuna]
      fono         = json[:fono]

      linea.info "email:"
      linea.info email
      linea.info "nombre"
      linea.info nombre
      linea.info "apellido"
      linea.info apellido
      linea.info "fono"
      linea.info fono
      linea.info "descripcion"
      linea.info descripcion
      linea.info "comuna"
      linea.info comuna
  
      linea.info "Síntomas"
      linea.info sintomas.inspect

      presupuesto_descripcion = presupuesto.descripcion

      #Alguien pidió una cotizacion desde Whatsapp
      #Esto ocurre porque un cliente interactuó con un digramaba unilineal
      #y llegamos hasta aquí
      #Renviamos la solicitud al proveedor y nos vamos
      if presupuesto.estado == "cotizacion"
        user =  ::User.find_by(:fono => presupuesto.fono)

        ::Waba::Transaccion.new(:colaborador).responder( C.fono_de_proveedor, mensaje_id, "Hola, le escribe #{user.name}, a través de la plataforma alectrico ®, para solicitarle una cotización para una instalación eléctrica, cuyo diagrama unilineal lo puede bajar desde link siguiente.")
        url = Rails.application.routes.url_helpers.download_unilineal_pdf_api_v1_electrico_presupuesto_url( :id => presupuesto.id, :host => C.api_url)
        ::Waba::Transaccion.new(:colaborador).enviar_url( C.fono_de_proveedor, url)

        ::Waba::Transaccion.new(:colaborador).enviar_circuitos_pdf_libre( presupuesto, C.fono_de_proveedor, C.nombre_de_proveedor, user.name)
        ::Waba::Transaccion.new(:colaborador).enviar_contacto(presupuesto.fono, user)

       # ::Waba::Transaccion.new(:colaborador).say_disyuntor(presupuesto.fono, presupuesto)
        return
      end

      if sintomas.any?
        linea.info "Síntomas"
        sintomas.each do |sintoma|
          linea.info sintoma
          case sintoma
          when "0"
            texto_sintoma="Sentí un ruido de cuetazo"
          when "1"
            texto_sintoma="Tengo enchufe(s) malo(s)"
          when "2"
            texto_sintoma="Necesito instalar luminarias"
          when "3"
            texto_sintoma="Necesito presentar un TE1"
          when "4"
            texto_sintoma="Necesito más circuitos"
          when "5"
            texto_sintoma="No tengo luz"
          end

          presupuesto_descripcion = "#{presupuesto_descripcion} | #{texto_sintoma}"
          linea.info presupuesto_descripcion
        end
      else
        linea.info "No hay síntomas"
      end

      usuario = crear_usuario( fono, nombre, email )
      #si el fono del presupuesto existente no es el mismo del usuario
      #entonces creamos un presupuesto nuevo y lo marcamos con el fono
      #del nuevo usuario, de esta forma evitamos que el que originó
      #el presupuesto lo modifique a voluntad
      #al intentar crear un presupuesto nuevo, es posible que el callback intente borrar
      #al presupuesto existente, porque es sea el último presupuesto efímero
      rendicion =  ::Operacion::Rendicion.find_by(:presupuesto_id => presupuesto.id)

      if rendicion.present?
        presupuesto.update({:efimero => false, :vigente => false})
      else
        presupuesto.destroy
      end



      presupuesto_nuevo = ::Electrico::Presupuesto.create( 
         {:usuario => usuario, 
         :descripcion => presupuesto_descripcion,
         :direccion => direccion, 
         :comuna => comuna, 
         :efimero => true,
         :fono => fono})

      if sintomas.any?
        sintomas.each do |sintoma|
          case sintoma
          when "0"
            texto_sintoma="Sentí un ruido de cuetazo"
            presupuesto_nuevo.update(:reparar => true)
          when "1"
            texto_sintoma="Tengo enchufe(s) malo(s)"
            presupuesto_nuevo.update(:reparar => true)
          when "2"
            texto_sintoma="Necesito instalar luminarias"
            presupuesto_nuevo.update(:instalar => true)
          when "3"
            texto_sintoma="Necesito presentar un TE1"
            presupuesto_nuevo.update(:certificar => true)
          when "4"
            texto_sintoma="Necesito más circuitos"
            presupuesto_nuevo.update(:ampliar => true)
          when "5"
            texto_sintoma="No tengo luz"
            presupuesto_nuevo.update(:reparar => true)
          end
        end
      end


      presupuesto_nuevo.comunicar

      conserje = ::User.find_by(:fono => fono_conserje)
      if fono != fono_conserje
        mensaje = "#{conserje.name}, estamos solicitando el pago a otra persona. No considere los links de pagos que le hemos envíado a Ud."
        ::Waba::Transaccion.new(:cliente).responder( fono_conserje, mensaje_id, mensaje)
        ::Waba::Transaccion.new(:cliente).enviar_confirmar_fono( presupuesto_nuevo)
        mensaje = "Hola, #{conserje.name} ha solicitado una visita a domicilio en alectrico®, a ser efectuada en su nombre, ahora puede pagar la visita siguiendo el link:"
        ::Waba::Transaccion.new(:cliente).responder( fono, mensaje_id, mensaje)
        auth_token = ::Waba::Transaccion.new(:admin).autoriza( presupuesto_nuevo.usuario)
        url_de_pago="#{C.api_url}/api/v1/electrico/presupuestos/#{presupuesto_nuevo.remember_token}/pagar_oferta/?auth_token=#{auth_token}"
        ::Waba::Transaccion.new(:cliente).enviar_url(fono, url_de_pago)

        mensaje = "Si no conoce a #{conserje.name}, fono: #{conserje.fono}, ignore este mensaje por favor y escríbanos a alectrico@outlook.cl informando el fono para que podamos bloquearlo"
        ::Waba::Transaccion.new(:cliente).responder( fono, mensaje_id, mensaje)
        mensaje = "En el chat escriba /presupuesto para revisar los datos de la atención. Puede corregir su email digitando /email, su dirección digitando /direccion, la descripción del problema con /descripcion. Tambíen puede conocer nuestros precios digitando /catalogo. Por último puede obtener un diagrama para su tablero eléctrico digitando /unilineal"
        ::Waba::Transaccion.new(:cliente).responder( fono, mensaje_id, mensaje)
        mensaje = "Por favor llame para que le confirmen la recepción en el WhatsApp del fono que Ud. informó"
        ::Waba::Transaccion.new(:cliente).say_mensaje_de_exito( presupuesto_nuevo, conserje, mensaje )
      else
        mensaje = "Genial, ya anotamos la solicitud de atención"
        ::Waba::Transaccion.new(:cliente).say_mensaje_de_exito( presupuesto_nuevo, conserje, mensaje )
      end
    end

    def to_json(*a)
      data = {  'response_json'  => @response_json,
                'body'           => @body,
                'name'           => @name  }
      { 'json_class' => self.class.name,
        'data' => data.to_json(*a) }
    end
    
    def self.json_create(o)
      attrs       = JSON.parse(o['data'], :quirks_mode => true )
      response_json = attrs['response_json']
      body          = attrs['body']
      name          = attrs['name']

      n = ::Graph::NfmReply.new(
        response_json,
        body,
        name  )
    end

    def monito(msg_id=nil)
      " (nfm_reply (msg_id #{msg_id}) (id #{@response_json}))"
    end

    def put
      " (nfm_reply (id #{@resonse_json}))"
    end

  end
end
