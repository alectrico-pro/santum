
#A veces tengo un error :\"Cannot send message to the same consumer phone number as the sender phone number
#Esto se debe a que el receptor del mensaje (es un colaborador) tiene el mismo número que el waba que 
#origina la imagen.
#Para resolver entrar como admin y cambiar el fono a ese colaborador
#También colocar una validación en el modelo de user o de colaborador para
#Evitar que use números coincidentes con los de los waba:
#Son logueadas a la agenda de hecho en AGENDA
#Esa AGENA  se usa para almacenar hechos para
#el experty system remoto
#Adicionalmente los WABA que se puedan asociar
#a un presupuesto se agregan como llamadas a ese presupuesto
#Esa asociación se puede hacer aquí o en el origen del
#llamado
=begin
Tipos de mensajes que se pueden enviar
#POST /v1/messages
{
  "recipient_type": "individual",
  "to": "whatsapp-id",
  "type": "audio" | "contact" | "document" | "image" | "location" | "sticker" | "text" | "video",

  "audio": {
    "id": "your-media-id"
  }

  "document": {
    "id": "your-media-id",
    "filename": "your-document-filename"
  }

  "document": {
    "link": "the-provider-name/protocol://the-url",
    "provider": {
        "name" : "provider-name"
    }
  }

  "document": {
    "link": "http(s)://the-url.pdf"
  }

  "video": {
    "id": "your-media-id"
  }

  "image": {
    "link": "http(s)://the-url",
    "provider": {
        "name" : "provider-name"
    }
  }

  "image": {
    "id": "your-media-id"
  }

  "sticker": {
    "id": "your-media-id"
  }

  "sticker": {
    "link": "http(s)://the-url",
    "provider": {
      "name" : "provider-name"
    }
  }
}
#Estos son los waba y su relación con un presupuesto                                     
#Las pruebas se refieren a si son grabadas o no en el modelo grabador
#                             hijo de   | testigo     |  invocante        | pruebas  |
#transacción            | presupuesto   | modelo      |  modelo           | dev | op |
#say_hola               |     NO        |             |                   |     |    | 
#say_recargar           |     NO        |             |                   |     |    |
#enviar_mensaje         |     NO        |             |                   |     |    |
#enviar_ubicacion       |               |             |                   |     |    |
#enviar_url             |               |             |                   |     |    |
#enviar_documento       |     NO        |             |                   |     |    |
#enviar_presupuesto_pdf |     SÍ        |  llamada    | Waba::Transaccion |     |    |
#enviar_circuitos_pdf   |     SÍ        |  llamada    | Waba::Transaccion |     |    |
#say_toma               |     SÍ        |  llamada    | Waba::Transaccion |  v  | v  |
#say_ayuda              |               |             |                   |     |    |
#say_toma_en_app        |     SÍ        |  llamada    | Waba::Transaccion |  v  | v  |
#say_oferta             |     SÍ        |  llamada    | Waba::Transaccion |  v  | v  |
#say_fail               |     NO        |             |                   |     |    |
##say_exito             |     NO        |  llamada    | controller.webhook|  v  | v  |
#say_mensaje_de_exito   |     NO        |             | controller.webhook|  v  | v  |
#enviar_contactos       |               |             |                   |     |    |
#enviar_single          |     NO        |             | controller.webhook|     |    |
#enviar_multi           |     NO        |             | controller.webhook|     |    |
#say_reservar           |     SÍ        |             |                   |  v  | v  | "es rapido-el usuario debe iniciar
#llama_al_flow          |     NO        |             |                   |  v  | v  | "es lento- usa un template que lo invoca
#say_flow_reservar      |     NO        |             |                   |  v  | v  | "es lento- usa un tempolate que lo invoca
#-------------------------------------------------------------------------------------
#                                                     | PretpConrller#hola |    |    |
#                                                     | Presupuesto.hola   |    |    |
#say_bienvenido         |     SÍ        |  llamada    | Waba::Transaccion  |    |    |
#
=end
class Waba::Transaccion 
  extend Linea
  include Linea

  attr_reader :api_version
  attr_reader :token
  attr_reader :phone
  attr_reader :waba_id

  #include HTTParty
  #include ::Biblioteca::Mensajeria

  #publico es un symbol (:cliente|:colaborador
  def initialize( publico )

    linea.debug "En Waba::Transaccion.initialize"

    @marca        = WabaCfg.marca

    linea.info "publico es: #{publico}"
    #1000 diarios
    #932000849
    #alectrico: Servicios Profesionales
    #figura: un electricista

    #Esto es importante, pues hay dos números de teléfono
    #Uno de ellos estará abierto al púlico para que
    #genere órdenes
    #El otro no, pero sí estará abierto a los colaboradores
    #y los admins
    #En un futuro los colaboradores podrán obtener los servicios
    #en sus whatsapp
    #
    case publico
    when :sistema
      linea.info "detectado sistema"
      @waba_id     = WabaCfg.waba_id_colaboradores
      @phone_id    = WabaCfg.phone_id_colaboradores
      @catalog_id  = WabaCfg.catalog_id_colaboradores
    when :admin
      linea.info "detectado admin"
      @waba_id     = WabaCfg.waba_id_colaboradores
      @phone_id    = WabaCfg.phone_id_colaboradores
      @catalog_id  = WabaCfg.catalog_id_colaboradores
    when :cliente
      linea.info "detectado cliente"
      @waba_id     = WabaCfg.waba_id_clientes
      @phone_id    = WabaCfg.phone_id_clientes
      @catalog_id  = WabaCfg.catalog_id_clientes
     when :colaborador
       linea.info "detectado colaborador"
      @waba_id     = WabaCfg.waba_id_colaboradores
      @phone_id    = WabaCfg.phone_id_colaboradores
      @catalog_id  = WabaCfg.catalog_id_colaboradores
      #wip
     when :alec
      @waba_id     = WabaCfg.waba_id_alec
      @phone_id    = WabaCfg.phone_id_alec
      @catalog_id  = WabaCfg.catalog_id_alec
    else
      raise "Debe pasar el parámetro publico en initialize de Waba::Transaccion"
    end

   # @ae_id        = AE_ID
    #@ae_secret    = AE_SECRET

    @base_uri     = WabaCfg.base_uri
    base_uri      = @base_uri
    @api_version  = WabaCfg.api_version
    @token        = TOKEN #este Token se genera en la herramienta explorador de API Graph, 
    #se debe usar variable de ambiente META_USER_TOKEN
    #se inicia en el inicializador waba.rb
    #Atención: Para obtenerla en el expolorador graph seleccion
    #token de app y luego generar. S
    #is genera token de usuario durará una hora
    #en https://developers.facebook.com/tools/explorer/
    @to           = WabaCfg.to
    @headers = {"Content-Type": "application/json", Authorization: "Bearer #{@token}"}

  end

  
  def confirmar_fono( fono, nombre) 

    fono   = C.fono_test if Rails.env.test?

    linea.info "En Transaction confirmar_fono"

    body= {
        "messaging_product" => "whatsapp",
        "to"                => fono,
        "type"              => "template",
        "template"          => {
          "name"            => "otp",
          "language"        => {
            "code"          => "es"
          },
        "components"        => [
          { "type"          => "header", "parameters" => [
          { "type"          => "image",
            "image"          => { "link": WabaCfg.imagen_enviar_confirmar_fono_url } } ] },
          { "type"          => "body"  , "parameters" => [
          { "type"          => "text",
            "text"          => nombre      } ] }
         ]}
       }



    if send body
      return true
    else
      return false
    end

  end




  #llama al template flow_reservar, aparece con una casa led 
  #y un botón Confirmar Datos
  #usar sin imágenes para tiempo de respuesta de 5segundos
  #flow_reservar invoca a un flujo interconstruido
  #
  def say_flow_reservar( fono, nombre )
    linea.info "En say_flow_reservar"
    body = {
        "messaging_product": "whatsapp",
        "to": fono,
        "type": "template",
        "template": {
          "name": "flow_reservar",
          "language": {
            "code": "es"
          },
        "components": [
          { "type": "body" , "parameters": [ { "type": "text",  "text": nombre} ] },
          { "type": "header", "parameters": [ { "type": "image",
              "image": {  "link": WabaCfg.image_url_say_ofertar } } ] },
          { "type": "button", "sub_type": "flow",  "index": "0" }
         ]
        }
       }

    linea.info "body"
    linea.info body

    if send body
      return true
    else
      return false
    end

  end





  #Y es probable que sea el culpable por
  #el envío duplicado de los mensajes
  #waba
  def send body, presupuesto=nil, fono=nil

    linea.warn "__method__: #{__method__.to_s} "
    waba_orden = caller_locations.first.base_label
    begin
      linea.warn "Llamado desde #{waba_orden}"
    rescue StandardError => e
      linea.error e.message
    end
    #@app_token = get_app_access_token

    #linea.info "app_token #{@app_token}"

    options = { headers: @headers, body: body.to_json }
    url     = "#{@base_uri}/#{@api_version}/#{@waba_id}/messages"

    begin
      request = ::HTTParty.post( url, options )

      if request.response.class == ::Net::HTTPOK
        resultado = "El socket emitió exitosamente el request Waba"

        #---------------------- Webpush a Instaladores -------------------
        texto_mensaje = "WABA #{waba_orden} enviado para #{User.find_by(:fono => fono)&.name} #{fono} a #{presupuesto.usuario.nombre} #{presupuesto.comuna.upcase} | #{presupuesto.descripcion}"
  
        Instalador.all.activos.each{|instalador|
          mensaje = {
                  title:           'Aviso a Instalador',
                   body:           texto_mensaje,
                   tag:            "#{waba_orden}-presupuesto:#{presupuesto.id}",
                   tipo:           'aviso_a_instalador',
                   receiver_id:    instalador.id,
                   presupuesto_id: (presupuesto.nil? ? 0 : presupuesto.id ),
                   icon:           '/img/ticket.png',
                   image:          '/img/wide-landing-04.jpg',
                   badge:          '/img/ticket.png'}
          push_to( instalador, mensaje )
        } 
        #-----------------------------------------------------------------------------------------------
        body     = JSON.parse(request.parsed_response)

	begin
          fact     = ::Graph::Fact.new(body)
          id       = fact&.messages&.first&.id
	  if fact.error
            error = fact.error
            linea.info "Error: "
            linea.info error.code
	    procesa_error(request.parsed_response, presupuesto, fono)
	  end

          if id and presupuesto
	    linea.info "Tratando de vinculara a algún presupuesto"
	    linea.error "El presupuesto no tiene usuario" if presupuesto.usuario.nil?
            carrier = ::Electrico::Carrier.create(\
             :nombre => id, \
             :tarifa => presupuesto.id)
            linea.warn "Creado carrier 1"
            linea.warn carrier.inspect
	    if presupuesto.usuario
              llamada =  presupuesto.llamadas.create(
               :minutos        => 0,
                :costo          => 0,
                :contenido      => id,
                :carrier_id     => carrier.id,
                :fono           => presupuesto.usuario.fono
               )
	    end
          end

        rescue SocketError => e
	  linea.warn "Ocurrió un Error de Socket"
	  if Rails.env.test?
	    linea.info "Como es Rails.env.test se retornará true"
            return true		
	  else
	    return false
	  end
        rescue ActiveRecord::ConnectionTimeoutError => e
          #https://www.honeybadger.io/blog/how-to-try-again-when-exceptions-happen-in-ruby/
          linea.warn "Ocurrió un Error de Conexión a la base de datos"
          if Rails.env.test?
            linea.info "Como es Rails.env.test se cerrarán las conexiones y se reintentará"
	    #ActiveRecord::Base.connection.close
	    #https://bibwild.wordpress.com/2014/07/17/activerecord-concurrency-in-rails4-avoid-leaked-connections/
	    ActiveRecord::Base.clear_active_connections!
	    retry
          else
            return false
          end

        rescue Net::HTTPBadRequest => e
	  linea.error "Ocurrió un error BadRequest"
	  code = procesa_error(body, presupuesto, fono)
          case code
          when 131009
	    linea.info "El error es 131009, se debe generalmente a un número de teléfono que Facebook no puede procesar"
	    linea.info "No se insistirá. Se enviará un solo mensaje fallback"
            return true
          else
            return false
          end

        rescue StandardError => e
          linea.info e.inspect
          linea.error "Error procesando mensaje waba con Graph::Fact"
	  linea.info "Podemos suponer que la solicitud Waba nunca llegó a Facebook"
	  linea.info "Nada más podemos hacer por ahora"
          linea.info "Pero podemos procesar el error"
          code = procesa_error(body, presupuesto, fono)
	  case code
	  when 131009
	    #este error ocurre cuando se intentan enviar un mensaje a un número
		  #de teléfono que no es válido. Este es un código de waba facebook
	    #no se reintentará enviándolo de nuevo, pues generará un ciclo infinito
		  #Dado que nunca se responderá con ok
            return true
	  else
            return false
	  end
        end

      else
        linea.info "Generando un error estandard para que lo vea Typhoeus"
        linea.info "La respuesta es:"
        linea.error request.parsed_response.inspect
        linea.error request.response.inspect
        procesa_error(request.parsed_response, presupuesto, fono) 
       # raise StandardError

      end
    rescue SocketError => e
      linea.error "Ocurrió un error de Socket. No se intentará  con Typhoeus"
      linea.error e.message
         if Rails.env.test?
            linea.info "Como es Rails.env.test se retornará true"
            return true
          else
            return false
          end

    rescue StandardError => e
     #------------------------------------- segundo intento en caso de fallo con HTTParty
      linea.error "Ocurrió un error al intentarlo con HTTParty, intentando ahora con Typhoeus"
      linea.error e.message
    end
  end

end

