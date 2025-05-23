
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
    linea.info "Imagen es:"
    linea.info WabaCfg.imagen_enviar_confirmar_fono_url 
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


  #{ "type": "text",  "text": nombre}

  #llama al template flow_reservar, aparece con una casa led 
  #y un botón Confirmar Datos
  #usar sin imágenes para tiempo de respuesta de 5segundos
  #flow_reservar invoca a un flujo interconstruido
  #hay que llamar al template
  #y este llama al flow reservar
  #reservar_productos_version_70
  #antes era flow_reservar
  #ahora es reservar_productos_version_70
  def say_flow_reservar( fono, nombre )
    linea.info "En say_flow_reservar"
    body = {
        "messaging_product": "whatsapp",
        "to": fono,
        "type": "template",
        "template": {
          "name": "disyuntor",
          "language": {
            "code": "es"
          },
        "components": [
          { "type": "body" , "parameters": [ ] },
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


  #permite mostrarlo con un área en whatsapp
  #que puede mover el feed hacia el mensaje que se haya respondido
  def responder( fono, id_de_contexto, mensaje)
    #Nota: Parece que id_de_contexto funcionará 
    #como id de mensaje
    fono= "#{fono}"
    fono= C.fono_test if Rails.env.test?

    linea.info "En Transaction responder"

    linea.info "fono: "
    linea.info  fono


      body = {
          "messaging_product" =>  "whatsapp",
         "context": {
           "message_id": id_de_contexto
          },
          "recipient_type"    =>  "individual",
          "to"                =>  fono,
          "type"              =>  "text",
          "text"              =>  { "preview_url" => true,
                                    "body" => mensaje }
          }

    if send body
      return true
    else
      return false
    end
  end


  def send body
    linea.warn "__method__: #{__method__.to_s} "
    options = { headers: @headers, body: body.to_json }
    url     = "#{@base_uri}/#{@api_version}/#{@waba_id}/messages"
    begin
      request = ::HTTParty.post( url, options )
    rescue
     # TurboStream.
    end
    linea.info request.inspect
  end


  def set_read_to( wamid )

    linea.info "En Transacción set_read_to de WABA"
    linea.info "wamid #{wamid}"

    url          = "#{@base_uri}/#{@api_version}/#{@waba_id}/messages/"
    body = {
      "messaging_product": "whatsapp",
      "status": "read",
      "message_id": wamid
    }
    options      = { headers: @headers, body: body.to_json }
    response     = HTTParty.put( url, options )

    if send body
      return true
    else
      return false
    end

  end

  def set_delivered_to( wamid )

    linea.info "En Transacción set_delivered_to de WABA"
    linea.info "wamid: #{wamid}"

    url          = "#{@base_uri}/#{@api_version}/#{@waba_id}/messages/"

    body = {
      "messaging_product": "whatsapp",
      "status": "delivered",
      "message_id": wamid
    }

    if send body
      return true
    else
      return false
    end

  end



  def enviar_mensaje(fono, text)

    fono= "#{fono}"
    fono= C.fono_test if Rails.env.test?

    linea.info "En Transaction enviar_mensaje"

      body = {
          "messaging_product" =>  "whatsapp",
          "recipient_type"    =>  "individual",
          "to"                =>  fono,
          "type"              =>  "text",
          "text"              =>  { "preview_url" => true,
                                    "body" => text }
          }

    if send body
      return true
    else
      return false
    end
  end


  def say_toma( colaborador, reporte)

    fono    = colaborador.fono
    nombre  = colaborador.nombre
    sintoma = reporte.contenido
    comuna  = "Providencia"
    fono = C.fono_test if Rails.env.test?

    body = { "messaging_product" =>  "whatsapp",
          "to"                   =>  fono,
          "type"                 =>  "template",
          "template"             => { "name" => "tomar", "language" => { "code" => "es" },
          "components"           => [  { "type" =>   "body",
          "parameters" => [
            { "type"             =>   "text", "text" => "#{nombre}"     } ,
            { "type"             =>   "text", "text" => "#{sintoma}"     } ,
            { "type"             =>   "text", "text" => "#{comuna}"     }
            ] } ] }}


    if send 
      return true
    else
      return false
    end

  end



 def say_oferta( colaborador, reporte)

      linea.info "En Waba::Transaction.say_oferta de Waba"

      nombre  = colaborador.nombre
      fono    = colaborador.fono
      sintoma = reporte.contenido
      comuna  = "Providencia"
      fono= C.fono_test if Rails.env.test?


      WabaCfg.image_url_say_ofertar
      body = { "messaging_product" =>  "whatsapp",
          "to"                =>  fono,
          "recipient_type"    =>  "individual",
          "type"              =>  "template",
          "template"          => { "name": "dale",
                                   "language": { "code": "es",
                                                 "policy": "deterministic" },
          "components"         => [
            { "type"   => "header", "parameters": [
            { "type"   => "image",
              "image"  => { "link": WabaCfg.image_url_say_ofertar } } ] },
            { "type"   =>   "body",
          "parameters" => [
            { "type"   => "text", "text": "#{nombre}"     } ,
            { "type"   => "text", "text": "#{comuna}"     } ,
            { "type"   => "text", "text": "#{sintoma}"    }
            ] } ] }}

      if send body
        linea.info "Exito waba say_oferta"
        return true
      else
        linea.info "Falla en waba say_oferta"
        return false

      end

  end



end

