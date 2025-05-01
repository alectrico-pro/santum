
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

  attr_reader :api_version
  attr_reader :token
  attr_reader :phone
  attr_reader :waba_id

  include HTTParty
  include ::Biblioteca::Mensajeria

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

    @ae_id        = AE_ID
    @ae_secret    = AE_SECRET

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

  def autoriza( usuario )

    linea.info "En Transacción autoriza de WABA"
    valid_payload = {'user'=>{'email' => usuario.email}}
    coded_token   = JsonWebToken.encode(:reader => valid_payload )
    return coded_token

  end

#Mark as read no funciona para mi número de teléfono
#<HTTParty::Response:0x55922969d410 parsed_response="{\"error\":{\"message\":\"Unsupported put request. Object with ID '115409841173645' does not exist, cannot be loaded due to missing permissions, or does not support this operation. Please read the Graph API documentation at https:\\/\\/developers.facebook.com\\/docs\\/graph-api\",\"type\":\"GraphMethodException\",\"code\":100,\"error_subcode\":33,\"fbtrace_id\":\"AtL9AHCwXmsOGf74sIfHpJn\"}}", @response=#<Net::HTTPBadRequest 400 Bad Request readbody=true>, @headers={"vary"=>["Origin", "Accept-Encoding"], "access-control-allow-origin"=>["*"], "cross-origin-resource-policy"=>["cross-origin"], "x-app-usage"=>["{\"call_count\":0,\"total_cputime\":0,\"total_time\":0}"], "x-fb-rlafr"=>["0"], "content-type"=>["text/javascript; charset=UTF-8"], "www-authenticate"=>["OAuth \"Facebook Platform\" \"invalid_request\" \"Unsupported put request. Object with ID '115409841173645' does not exist, cannot be loaded due to missing permissions, or does not support this operation. Please read the Graph API documentation at https://developers.facebook.com/docs/graph-api\""], "facebook-api-version"=>["v14.0"], "strict-transport-security"=>["max-age=15552000; preload"], "pragma"=>["no-cache"], "cache-control"=>["no-store"], "expires"=>["Sat, 01 Jan 2000 00:00:00 GMT"], "x-fb-request-id"=>["AtL9AHCwXmsOGf74sIfHpJn"], "x-fb-trace-id"=>["BkExDTfPrh/"], "x-fb-rev"=>["1005938380"], "x-fb-debug"=>["9zyGfetspT3oNHw4e1KYFxPHALrpFfjo6fDYV+onyFXbw4NpsQIriCX+4fkoSFaEJM6xcLB+XFkyQFxIvKQtSQ=="], "date"=>["Fri, 29 Jul 2022 20:30:35 GMT"], "priority"=>["u=3,i"], "transfer-encoding"=>["chunked"], "alt-svc"=>["h3=\":443\"; ma=86400, h3-29=\":443\"; ma=86400"], "connection"=>["close"]}>



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


  #no funciona
  #esto es para informarle a facebook
  #Cuáles son los sitios que almacenen
  #los archivos de medios que uno envíe
  def setea_providers( usuario )

    linea.info "En Transacción agregar_provider de WABA"

    valid_payload = {'user'=>{'email' => usuario.email}}
    coded_token   = JsonWebToken.encode(:reader => valid_payload )

    options = {
      headers: { 'Content-Type':  "application/json",
                 Authorization: "Bearer #{@token}"},
      body: { 
          name: C.api_url,
          type: "www",
    config: { bearer: coded_token } }.to_json  }

    url = "#{@base_uri}/#{@api_version}/#{@waba_id}/settings/application/media/providers"

    puts url
    response = HTTParty.get( url, options )

    if response.response.class == ::Net::HTTPOK
      return true
    else
      puts response.inspect
      return false
    end

  end

  def send_flow( fono )
    linea.info "En send_flow de waba"
    fono = "#{fono}"
    fono = C.fono_test if Rails.env.test?

    body = { "messaging_product" =>  "whatsapp",
             "to"                =>  fono,
             "type"              =>  "template",
            "template"           => { "name" => "send_flow",
                                      "language" => { "code" => "es" } }
    }
    if send body
      return true
    else
      return false
    end
  end

  def enviar_catalogo(fono)
    linea.info "En enviar_catalogo de waba"
    fono = C.fono_test if Rails.env.test?

    body = {"messaging_product": "whatsapp",
            "to": fono,
            "type": "template",
            "template": { "name": "catame",
            "language": { "code": "es"}, 
            "components": [
              {"type": "button",
               "index": 0,
               "sub_type": "CATALOG", 
               "parameters": [
                 {"type": "action",
                  "action": {"thumbnail_product_retailer_id": "gtin_corte_de_energia"}}]}]}}

   if send body
      return true
    else
      return false
    end

  end

  def enviar_catalogo_maquetas(fono)
    linea.info "En ::Waba::Transaction enviar_catalogo_maquetas"

    fono = C.fono_test if Rails.env.test?

    maquetas = Array.new

    ::Electrico::MaquetaEquipo.all.each{ |maqueta|
      maquetas <<  { "product_retailer_id": "#{maqueta.id}" }
    }
    maquetas_json = maquetas.to_json


    body = {
     "messaging_product": "whatsapp",
       "recipient_type": "individual",
       "to": "#{fono}",
       "type": "interactive",
       "interactive": {
         "type": "product_list",
         "header":{
           "type": "text",
           "text": "Elija del catálogo para diseñarle sus circuitos."
         },
         "body": {
           "text": "Electrodomésticos comunes para una casa pequeña."
         },
         "footer": {
           "text": "#{@marca}"
         },
         "action": {
           "catalog_id": "#{@catalog_id}",
           "sections": [
             {
               "title": "Electrodomésticos",
               "product_items":
               "#{maquetas_json}"
             }
           ]
         }
       }
     }

    if send body
      return true
    else
      return false
    end
  end


#  862452141913088
  #Enviar un par de servicios
  def enviar_multi(fono)
    mantenimientos = Array.new
    ::Comercio::Servicio.mantenimiento.each{ |servicio| 
      mantenimientos <<  { "product_retailer_id": "#{servicio.gtin}" }
    }
    mantenimientos_json = mantenimientos.to_json

    certificaciones = Array.new
    ::Comercio::Servicio.certificacion.each{ |servicio|
      certificaciones <<  { "product_retailer_id": "#{servicio.gtin}" }
    }
    certificaciones_json = certificaciones.to_json

    reparaciones = Array.new
    ::Comercio::Servicio.reparacion.each{ |servicio|
      reparaciones <<  { "product_retailer_id": "#{servicio.gtin}" }
    }
    reparaciones_json = reparaciones.to_json

  # los créditos no se envía para los clientes
    # Debe usarse otro sistema, aún no realizado
    # Para ofertar créditos a colaboradores
   # creditos = Array.new
   # ::Comercio::Servicio.creditos.each{ |servicio|
   #   creditos <<  { "product_retailer_id": "#{servicio.gtin}" }
   # }
   # creditos_json = creditos.to_json


    linea.info "En Transaction enviar_multi de catalogo"
    fono = "#{fono}"
    fono = C.fono_test if Rails.env.test?

    body = {
     "messaging_product": "whatsapp",
       "recipient_type": "individual",
       "to": "#{fono}",
       "type": "interactive",
       "interactive": {
         "type": "product_list",
         "header":{
           "type": "text",
           "text": "Servicios de Electricista."
         },
         "body": {
           "text": "Elija los servicios que necesita."
         },
         "footer": {
           "text": "#{@marca}"
         },
         "action": {
           "catalog_id": "#{@catalog_id}",
           "sections": [
             {
               "title": "Reparación",
               "product_items":
               "#{reparaciones_json}"
             },
             {
               "title": "Certificación",
               "product_items":
               "#{certificaciones_json}"
             },
             {
               "title": "Mantenimiento",
               "product_items":
               "#{mantenimientos_json}"
             }
           ]
         }
       }
     }

    if send body
      return true
    else
      return false
    end

  end



 
  def enviar_catalogo_de_productos(fono, en_moneda)

    productos = Array.new
    ( en_moneda.to_sym.to_proc ).call( ::Comercio::Servicio).productos.each{ |servicio|
      productos <<  { "product_retailer_id": "#{servicio.gtin}" }
    }
    productos_json = productos.to_json

    linea.info "En Transaction enviar_catalogo_de_productos"
    fono = "#{fono}"
    fono = C.fono_test if Rails.env.test?

    body = {
     "messaging_product": "whatsapp",
       "recipient_type": "individual",
       "to": "#{fono}",
       "type": "interactive",
       "interactive": {
         "type": "product_list",
         "header":{
           "type": "text",
           "text": "Whappy Hogar"
         },
         "body": {
           "text": "Elija los Mejores Electrodomésticos para su Hogar. Mensajería solo en *Ciudad de La Habana*. Entrega Rápida."
         },
         "footer": {
           "text": "#{@marca}"
         },
         "action": {
           "catalog_id": "#{@catalog_id}",
           "sections": [
             {
               "title": "Easy Cooking",
               "product_items":
               "#{productos_json}"
             }
           ]
         }
       }
     }

    if send body
      return true
    else
      return false
    end

  end



  def enviar_single( fono, id_producto)

    linea.info "En Transaction enviar_single de catalogo"
    linea.info "producto id es #{id_producto}"

    fono = "#{fono}"

    fono = C.fono_test if Rails.env.test?

    body = {
      "messaging_product"  => "whatsapp",
      "to"                 => "#{fono}",
      "recipient_type"     => "individual",
      "type"               => "interactive",
      "interactive"        => {
      "type"               => "product",
      "action"             => {
      "catalog_id"         => "#{@catalog_id}",
      "product_retailer_id"=>"#{id_producto}"}
      }
    }

    if send body
      return true
    else
      return false
    end

  end


  
  def enviar_boton_vale( presupuesto, gestor)

    linea.info "En Transaction say_vale de Waba"

    fono = "#{gestor.fono}"

    fono = C.fono_test if Rails.env.test?

    body = { "messaging_product" =>  "whatsapp",
             "to"                =>  fono,
             "type"              =>  "template",
            "template"           => { "name" => "vale",
                                      "language" => { "code" => "es" } }
    }

    if send body, presupuesto
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

    if send body
      return true
    else
      return false
    end

  end

  #llama al template llama_al_flow
  #El que a su vez llama a un flow
  #interconsturido como buton de completar formulario
  #Aparece como, Hola Necesitamos algunos datos
  #para concretar la visita a domicilio
  #Con un botón Reservar
  def llama_al_flow( fono, gtin)
    linea.info "En llama_a_flow"
     servicio = ::Comercio::Servicio.find_by(:gtin => gtin)
     linea.info "Servicio Encontrado" if servicio

     body= {
      "messaging_product": "whatsapp",
      "to": fono,
      "type": "template",
      "template": {
        "name": "llama_al_flow",
        "language": {
          "code": "es"
        },
      "components": [
        { "type": "header", "parameters": [
          { "type": "image",
            "image": {  "link": WabaCfg.image_url_say_ofertar }
          }
          ]
        },
        { "type": "button",
          "sub_type": "flow",
          "index": "0"
         }
       ]
      }
     }
    if send body
      return true
    else
      return false
    end

   end


   #Usa un interactive para llamar a un flow
   #publicado con id flow_id
  #Está marcado como marketing, es más caro
   def say_datos_de_entrega( fono, presupuesto, titulo, mensaje, titulo_del_boton)

     linea.info "En Transaction say_datos_de_entrega de Waba"

     body= {
        "recipient_type": "individual",
        "messaging_product": "whatsapp",
        "to": fono,
        "type": "interactive",
        "interactive": {
          "type": "flow",
         "header": {
            "type": "text",
            "text": titulo
          },
          "body": {
            "text": mensaje
          },
            "footer": {
              "text": "by alectrico®"
            },
            "action": {
              "name": "flow",
              "parameters": {
                "flow_message_version": "3",
                "flow_token": presupuesto.id,
                "flow_id": WabaCfg.flow_id_reservar_para_cuba,
                "flow_cta": titulo_del_boton,
                "flow_action": "navigate",
                "flow_action_payload": {
                  "screen": "CONTACTO",
                  "data": {
                    "nombre": presupuesto.descripcion,
                  }
                }
              }
            }
          }
        }

    if send body
      return true
    else
      return false
    end

   end


   #Usa un interactive para llamar a un flow
   #publicado con id flow_id
  #Está marcado como marketing, es más caro
   def say_reservar( fono, presupuesto)

     linea.info "En Transaction say_reservar de Waba"

     body= {
        "recipient_type": "individual",
        "messaging_product": "whatsapp",
        "to": fono,
        "type": "interactive",
        "interactive": {
          "type": "flow",
         "header": {
            "type": "text",
            "text": "Reserva de Servicio"
          },
          "body": {
            "text": presupuesto.descripcion
          },
            "footer": {
              "text": "alectrico®"
            },
            "action": {
              "name": "flow",
              "parameters": {
                "flow_message_version": "3",
                "flow_token": presupuesto.id,
                "flow_id": WabaCfg.flow_id_reservar,
                "flow_cta": "Reservar!",
                "flow_action": "navigate",
                "flow_action_payload": {
                  "screen": "SIGN_UP",
                  "data": {
                    "nombre": presupuesto.descripcion,
                  }
                }
              }
            }
          }
        }




    if send body
      return true
    else
      return false
    end

   end


   def say_disyuntor( fono, presupuesto)

     linea.info "En Transaction say_reservar de Waba"

     body= {
        "recipient_type": "individual",
        "messaging_product": "whatsapp",
        "to": fono,
        "type": "interactive",
        "interactive": {
          "type": "flow",
         "header": {
            "type": "text",
            "text": "Reserva de Servicio"
          },
          "body": {
            "text": presupuesto.descripcion
          },
            "footer": {
              "text": "alectrico®"
            },
            "action": {
              "name": "flow",
              "parameters": {
                "flow_message_version": "3",
                "flow_token": presupuesto.id,
                "flow_id": WabaCfg.flow_id_disyuntor,
                "flow_cta": "Diyuntor!",
                "flow_action": "navigate",
                "flow_action_payload": {
                  "screen": "ESPECIFICACION",
                  "data": {
                    "modelo": "DX3",
                    "In": "10 A",
                    "marca": "Legrand",
                    "precio": "100 CLP",
                    "Ia": "1000 A",
                    "poder_de_corte": "600 A",
                    "referencia": "8980809"
                  }
                }
              }
            }
          }
        }
    if send body
      return true
    else
      return false
    end
   end

   def say_ayuda( presupuesto, colaborador)

    linea.info "En Transaction say_ayuda de Waba"

    linea.warn "El colaborador no está activo" unless colaborador.activo

    return false unless colaborador.activo

    fono = "#{colaborador.fono}"
    fono = C.fono_test if Rails.env.test?

    body = { "messaging_product" =>  "whatsapp",
          "to"                   =>  fono,
          "type"                 =>  "template",
          "template"             => { "name" => "ayuda",
                                      "language" => { "code" => "es" } }
    }

    if send body, presupuesto
      return true
    else
      return false
    end

  end


  def say_toma( colaborador, presupuesto)

    return false unless colaborador.activo

    linea.info "En Transaction say_toma de Waba"

    if presupuesto.descripcion
      sintoma = presupuesto.descripcion.strip.upcase_first
    else
      sintoma = "No ha indicado descripción"
    end

    if presupuesto.comuna
      comuna  = presupuesto.comuna.strip.upcase
    else
      comuna  = "No ha informado comuna"
    end
    
    if colaborador.name
      name = colaborador.name.strip.split.first.upcase_first
    else
      name = "No ha dejado su nombre"
    end


    fono = "#{colaborador.fono}"
    fono = C.fono_test if Rails.env.test?

    body = { "messaging_product" =>  "whatsapp",
          "to"                   =>  fono,
          "type"                 =>  "template",
          "template"             => { "name" => "tomar", "language" => { "code" => "es" },
          "components"           => [  { "type" =>   "body",
          "parameters" => [
            { "type"             =>   "text", "text" => "#{name}"     } ,
            { "type"             =>   "text", "text" => "#{sintoma}"     } ,
            { "type"             =>   "text", "text" => "#{comuna}"     }
            ] } ] }}


    if send body, presupuesto
      return true
    else
      return false
    end

  end


  def say_oferta( colaborador, presupuesto)
   
      #Esto se le envía al colaborador para que elija tomar u ofertar 
      linea.info "En Waba::Transaction.say_oferta de Waba"
 
      #inea.error "Colaborador no está activo" unless colaborador.activo
      #inea.error "Presupuesto no existe" unless presupuesto

      #eturn false unless colaborador.activo and presupuesto
   

      if presupuesto&.descripcion
        sintoma = presupuesto.descripcion.strip.upcase_first
      else
        sintoma = "No ha indicado descripción"
      end

      if presupuesto&.comuna
        comuna  = presupuesto.comuna.strip.upcase
      else
        comuna  = "No ha informado comuna"
      end

      if colaborador&.name
        name = colaborador.name.strip.split.first.upcase_first
      else
        name = "No ha dejado su nombre"
      end

      fono = "#{colaborador.fono}"
      fono= C.fono_test if Rails.env.test?

      linea.info name
      linea.info comuna
      linea.info sintoma
      linea.info fono

=begin
      body = { "messaging_product" =>  "whatsapp",
          "to"                   =>  fono,
          "type"                 =>  "template",
          "template"             => { "name" => "tomar", "language" => { "code" => "es" },
          "components"           => [  { "type" =>   "body",
          "parameters" => [
            { "type"             =>   "text", "text" => "#{name}"     } ,
            { "type"             =>   "text", "text" => "#{sintoma}"     } ,
            { "type"             =>   "text", "text" => "#{comuna}"     }
            ] } ] }}

=end

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
            { "type"   => "text", "text": "#{name}"     } ,
            { "type"   => "text", "text": "#{comuna}"     } ,
            { "type"   => "text", "text": "#{sintoma}"    }
            ] } ] }}

      if send body, presupuesto, fono
	linea.info "Exito waba say_oferta"
        return true
      else
	linea.info "Falla en waba say_oferta"
        return false

      end

  end


  def say_bah( fono )

    linea.info "En Transaction say_bah de Waba"

    fono = "#{fono}"
    fono = C.fono_test if Rails.env.test?

    body = {
          "messaging_product" =>  "whatsapp",
          "to"                =>  fono,
          "type"              =>  "template",
          "template"          => {
            "name"            =>   "hola",
            "language"        => { "code" => "es" },
          :components         => [
            { "type"          =>   "header", "parameters" => [
            { "type"          =>   "image",
              "image"          => { "link" => WabaCfg.imagen_fail_url } } ] },
            { "type"          =>   "body", "parameters" => [
            { "type"          =>   "text",
              "text"          =>   "Bah! Ocurrió un error de nuestra parte, eso todo lo que podemos decir."    } ] }
           ]}}


    if send body
      return true
    else
      return false
    end
  end


  def say_fail( presupuesto, colaborador )

    linea.info "En Transaction say_fail de Waba"

    sintoma     = presupuesto.descripcion

    fono = "#{colaborador.fono}"
    fono = C.fono_test if Rails.env.test?

    body = {
          "messaging_product" =>  "whatsapp",
          "to"                =>  fono,
          "type"              =>  "template",
          "template"          => {
            "name"            =>   "hola",
            "language"        => { "code" => "es" },
          :components         => [
            { "type"          =>   "header", "parameters" => [
            { "type"          =>   "image",
              "image"          => { "link" => WabaCfg.imagen_fail_url } } ] },
            { "type"          =>   "body", "parameters" => [
            { "type"          =>   "text",
              "text"          =>   "No ha sido posible pasarle los datos de contacto del presupuesto: #{presupuesto.id}-#{sintoma}."    } ] }
           ]}}


    if send body, presupuesto
      return true
    else 
      return false
    end
  end

  def say_mensaje_de_exito( presupuesto, colaborador, mensaje )

    linea.info "En Transaction say_mensaje_de_exito de Waba"

    fono = "#{colaborador.fono}"
    fono = C.fono_test if Rails.env.test?

    sintoma     = presupuesto.descripcion

    body = {
          "messaging_product" =>  "whatsapp",
          "to"                =>  fono,
          "type"              =>  "template",
          "template"          => {
            "name"            =>   "hola",
            "language"        => { "code" => "es" },
          :components         => [
            { "type"          =>   "header", "parameters" => [
            { "type"          =>   "image",
              "image"         => { "link" => WabaCfg.image_url_exito } } ] },
            { "type"          =>   "body", "parameters" => [
            { "type"          =>   "text",
              "text"          =>   mensaje  } ] }
           ]}}


    if send body, presupuesto
      return true
    else
      return false
    end
  end




  def say_exito( presupuesto, colaborador )

    linea.info "En Transaction say_exito de Waba"

    fono = "#{colaborador.fono}"
    fono = C.fono_test if Rails.env.test?

    sintoma     = presupuesto.descripcion


    body = {
          "messaging_product" =>  "whatsapp",
          "to"                =>  fono,
          "type"              =>  "template",
          "template"          => {
            "name"            =>   "hola",
            "language"        => { "code" => "es" },
          :components         => [
            { "type"          =>   "header", "parameters" => [
            { "type"          =>   "image",
              "image"          => { "link" => WabaCfg.imagen_exito_url } } ] },
            { "type"          =>   "body", "parameters" => [
            { "type"          =>   "text",
              "text"          =>   "Qué bueno! Ya puede llamar a #{presupuesto.usuario.nombre}, al *#{presupuesto.usuario.fono}* o enviarle un correo a *#{presupuesto.usuario.email}* para que pueda conversar sobre _#{sintoma}_. Esta es la direccion: #{presupuesto.direccion}."   } ] }
           ]}}



    if send body, presupuesto
      return true
    else 
      return false
    end
  end



  def say_pedido_tomado( presupuesto, usuario )

    linea.info "En Transaction say_pedido_tomado"

    fono = "#{usuario.fono}"
    fono = C.fono_test if Rails.env.test?


    body = {
          "messaging_product" =>  "whatsapp",
          "to"                =>  fono,
          "type"              =>  "template",
          "template"          => {
            "name"            =>   "hola",
            "language"        => { "code" => "es" },
          :components         => [
            { "type"          =>   "header", "parameters" => [
            { "type"          =>   "image",
              "image"          => { "link" => WabaCfg.imagen_exito_url } } ] },
            { "type"          =>   "body", "parameters" => [
            { "type"          =>   "text",
              "text"          =>   "Qué bueno! Su pedido ya ha sido tomado por un proveedor, *Whappy Hogar* agradece su preferencia y le desea una feliz compra con su proveedor!"   } ] }
           ]}}



    if send body, presupuesto
      return true
    else
      return false
    end
  end

  def say_pedido_no_tomado( presupuesto, usuario )

    linea.info "En Transaction say_pedido_no_tomado"

    fono = "#{usuario.fono}"
    fono = C.fono_test if Rails.env.test?


    body = {
          "messaging_product" =>  "whatsapp",
          "to"                =>  fono,
          "type"              =>  "template",
          "template"          => {
            "name"            =>   "hola",
            "language"        => { "code" => "es" },
          :components         => [
            { "type"          =>   "header", "parameters" => [
            { "type"          =>   "image",
              "image"          => { "link" => WabaCfg.imagen_fail_url } } ] },
            { "type"          =>   "body", "parameters" => [
            { "type"          =>   "text",
              "text"          =>   "Bah! Su pedido no pudo ser tomado por un proveedor. *Whappy Hogar* agradece su preferencia y le espera en una próxima compra!"   } ] }
           ]}}



    if send body, presupuesto
      return true
    else
      return false
    end
  end


  def cotizar_proveedor(fono, nombre)

    linea.info "En Transaction cotizar_proveedor"

    presupuesto = ::Electrico::Presupuesto.find_by(:fono => fono)
    fono = "#{fono}"
    fono = C.fono_test if Rails.env.test?

    body = {
          "messaging_product" =>  "whatsapp",
          "to"                =>  fono,
          "type"              =>  "template",
          "template"          => {
            "name"            =>   "cotizar_proveedor",
            "language"        => { "code" => "es" },
          :components         => [
            { "type"          =>   "header", "parameters" => [
            { "type"          =>   "image",
             "image"          => { "link" => WabaCfg.image_url_say_ofertar } } ] },
            { "type"          =>   "body", "parameters" => [
            { "type"          =>   "text",
              "text"          =>   "#{nombre}"     } ] },
             { "type": "button",
               "sub_type": "flow", 
               "index": "0",
               "parameters": [{"type": "action", 
                               "action": {"flow_token": presupuesto.id,
                                          "flow_action_data": { "data": { "nombre": "chicho" }}}} ]}
            ]}}

    if send body
      return true
    else
      return false
    end
  end



  def say_hola(fono, mensaje)

    linea.info "En Transaction say_hola de Waba"

    fono = "#{fono}"
    fono = C.fono_test if Rails.env.test?

    body = {
          "messaging_product" =>  "whatsapp",
          "to"                =>  fono,
          "type"              =>  "template",
          "template"          => {
            "name"            =>   "hola",
            "language"        => { "code" => "es" },
          :components         => [
            { "type"          =>   "header", "parameters" => [
            { "type"          =>   "image",
             "image"          => { "link" => WabaCfg.image_url_say_ofertar } } ] },
            { "type"          =>   "body", "parameters" => [
            { "type"          =>   "text",
              "text"          =>   "#{mensaje}"     } ] }
           ]}}


    if send body
      return true
    else
      return false
    end
  end



    def feliz_navidad(user)

    linea.info "En Transaction feliz_navidad de Waba"

    fono = "#{user.fono}"
    #ono = user.fono
    fono = C.fono_test if Rails.env.test?

    body = {
          "messaging_product" =>  "whatsapp",
	  "to"                =>  fono,
          "type"              =>  "template",
          "template"          => {
            "name"            =>   "feliz_navidad",
            "language"        => { "code" => "es" },
          :components         => [
            { "type"          =>   "header", "parameters" => [
            { "type"          =>   "image",
             "image"          => { "link" => WabaCfg.imagen_url_feliz_navidad } } ] } ]}}


    if send body
      return true
    else
      return false
    end
  end

  def say_token_bat(user)

    linea.info "En Transaction say_token_bat de Waba"

    fono = "#{user.fono}"
    fono = C.fono_test if Rails.env.test?

    body = {
          "messaging_product" =>  "whatsapp",
          "to"                =>  fono,
          "type"              =>  "template",
          "template"          => {
            "name"            =>   "token_bat",
            "language"        => { "code" => "es" },
          :components         => [
            { "type"          =>   "header", "parameters" => [
            { "type"          =>   "image",
             "image"          => { "link" => WabaCfg.imagen_url_token_bat } } ] } ]}}


    if send body
      return true
    else
      return false
    end
  end


  def say_recargar(colaborador)

    fono = "#{colaborador.fono}"
    fono= C.fono_test if Rails.env.test?

    linea.info "En Transaction say_recargar de Waba"
      body = {
          "messaging_product" =>  "whatsapp",
          "to"                =>  fono,
          "type"              =>  "template",
          "template"          => {
            "name"            =>   "recargar",
            "language"        => { "code" => "es" },
          :components         => [
            { "type"          =>   "header", "parameters" => [
            { "type"          =>   "image",
              "image"         => { "link" => WabaCfg.imagen_recargar_url} } ] },
            { "type"          =>   "body", "parameters" => [
            { "type"          =>   "text",
              "text"          =>   "#{colaborador.name.upcase_first}"     } ] }
           ]}}


    if send body
      return true
    else
      return false
    end
  end

  def say_toma_en_app( colaborador,  presupuesto )

    return false unless colaborador.activo

    linea.info "En Transaction say_toma_en_app de Waba"

    comuna         = presupuesto.comuna
    sintoma        = presupuesto.descripcion
    presupuesto_id = presupuesto.id

    fono = "#{colaborador.fono}"
    fono = C.fono_test if Rails.env.test?


    body = {
      "messaging_product" => "whatsapp",
      "to" => fono,
      "type" => "template",
      "template" => {
        "name" => "nuevo_servicio",
        "language" => { "code": "es_AR" },
        "components" => [ { "type": "header",  "parameters": [
      { "type" => "text",  "text": "#{comuna.upcase}" } ] },
      { "type" => "body",    "parameters": [
      { "type" => "text",  "text": "#{colaborador.name.upcase_first}" } ,
      { "type" => "text",  "text": "#{sintoma.upcase_first}" },
      { "type" => "text",  "text": "#{comuna.upcase_first}" } ] } ,
      { "type" => "button","sub_type": "url","index":"0",
        "parameters" => [  { "type": "text",
        "text" => "/electrico/presupuestos/#{presupuesto_id}/aceptar_contrato_y_tomar_presupuesto" } ] } ] } }

    if send body, presupuesto
      return true
    else
      return false
    end

  end


  def say_comunas(fono, presupuesto_id)

    comunas = Array.new
    COMUNAS_PERMITIDAS.split(".").each{ |comuna|
      comunas << { :type => "reply", :reply => { :id => "#{comuna.capitalize}#{presupuesto_id}", :title => "#{comuna.capitalize}"}}
    }

    tamano = COMUNAS_PERMITIDAS.split(".").size
    grupos = (tamano / 3) 

    inicio = 0
    for i in (grupos).downto(0)
      inicio = 3*i
      fin    = 3*i + 2
      comunas_json = comunas[(inicio)..(fin)].as_json
      fono = "#{fono}"
      fono = C.fono_test if Rails.env.test?

      body = {
              "messaging_product"       => "whatsapp",
              "recipient_type"          => "individual",
              "to"                      => fono,
              "type"                    => "interactive",
              "interactive"             => {
                "type"                  => "button",
                "body"                  => {
                  "text"                => "COMUNAS"
                },
                "action"                => {
                  "buttons"             => comunas_json 
                }
              }
            }
      send body
    end
    return true
  end


  def say_interactive_con_boton(fono)

      fono = "#{fono}"
      fono = C.fono_test if Rails.env.test?

      body = {
          "messaging_product"       => "whatsapp",
          "recipient_type"          => "individual",
          "to"                      => fono,
          "type"                    => "interactive",
          "interactive"             => {
            "type"                  => "button",
            "body"                  => {
              "text"                => "BUTTON_TEXT"
            },
            "action"                => {
              "buttons"             => [
                {
                  "type"            => "reply",
                  "reply"           => {
                    "id"            => "UNIQUE_BUTTON_ID_1",
                    "title"         => "BUTTON_TITLE_1"
                  }
                },
                {
                  "type"            => "reply",
                  "reply"           => {
                    "id"            => "UNIQUE_BUTTON_ID_2",
                    "title"         => "BUTTON_TITLE_2"
                  }
                }
              ]
            }
          }
        }

    if send body
      return true
    else
      return false
    end

  end



  def say_interactive(fono)

      fono = "#{fono}"
      fono = C.fono_test if Rails.env.test?

      body = {
          "messaging_product"       => "whatsapp",
          "recipient_type"          => "individual",
          "to"                      => fono,
          "type"                    => "interactive",
          "interactive" => {
            "type"                  => "list",
            "header"                => {
              "type"                => "text",
              "text"                => "HEADER_TEXT"
            },
            "body"                  => {
              "text"                => "BODY_TEXT"
            },
            "footer"                => {
              "text"                => "FOOTER_TEXT"
            },
            "action"                => {
              "button"              => "BUTTON_TEXT",
              "sections"            => [
                {
                  "title"           => "SECTION_1_TITLE",
                  "rows"            => [
                    {
                      "id"          => "SECTION_1_ROW_1_ID",
                      "title"       => "SECTION_1_ROW_1_TITLE",
                      "description" => "SECTION_1_ROW_1_DESCRIPTION"
                    },
                    {
                      "id"          => "SECTION_1_ROW_2_ID",
                      "title"       => "SECTION_1_ROW_2_TITLE",
                      "description" => "SECTION_1_ROW_2_DESCRIPTION"
                    }
                  ]
                },
                {
                  "title"           => "SECTION_2_TITLE",
                  "rows"            => [
                    {
                      "id"          => "SECTION_2_ROW_1_ID",
                      "title"       => "SECTION_2_ROW_1_TITLE",
                      "description" => "SECTION_2_ROW_1_DESCRIPTION"
                    },
                    {
                      "id"          => "SECTION_2_ROW_2_ID",
                      "title"       => "SECTION_2_ROW_2_TITLE",
                      "description" => "SECTION_2_ROW_2_DESCRIPTION"
                    }
                  ]
                }
              ]
            }
          }
        }

    if send body
      return true
    else
      return false
    end
  end

  
  def confirmar_fono( reporte) 

    fono   = reporte.fono
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



  def enviar_confirmar_fono( presupuesto)

    usuario = presupuesto.usuario
    nombre = usuario.nombre

    fono   = "#{usuario.fono}"
    fono   = C.fono_test if Rails.env.test?

    linea.info "En Transaction enviar_confirmar_fono"

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



    if send body, presupuesto
      return true
    else
      return false
    end

  end




  def say_datos_bancarios( presupuesto, to_fono)

    linea.info "En Transaction say_datos_bancarios"

    body= {
        "messaging_product" => "whatsapp",
        "to"                => to_fono,
        "type"              => "template",
        "template"          => {
          "name"            => "say_datos_bancarios",
          "language"        => {
            "code"          => "es"
          },
        "components"        => [
          { "type"          => "header", "parameters" => [
          { "type"          => "image",
            "image"          => { "link" => C.datos_bancarios_imagen_url } } ] },
          { "type"          => "body",
            "parameters" => [
          { "type"          => "text",
            "text"          => presupuesto.nombre_banco },
          { "type"          => "text",
            "text"          => presupuesto.titular_banco   },
          { "type"          => "text",
            "text"          => presupuesto.cuenta_banco },
          { "type"          => "text",
            "text"          => presupuesto.fono_titular }
            ]}]}}

    if send body, presupuesto
      return true
    else
      return false
    end

  end



  #Cuando no estoy al día en los pagos de facebook no se envía
  #Versión para ser usada desde fifito
  def fifito_vale_de_mensajeria( presupuesto, carga, to_fono )

    #El fono es el del mayorista
    #Los datos del comprador están en el presupuesto en los campos name y fono

   #auth_token = ::Waba::Transaccion.new(:admin).autoriza( usuario)
   #url_de_pago="#{C.api_url}/api/v1/electrico/presupuestos/#{presupuesto.remember_token}/pagar_oferta/?auth_token=#{auth_token}"
   #::Waba::Transaccion.new(:cliente).enviar_url( fono, url_de_pago)

    producto = carga.tipo_equipo.servicio

    url_de_producto = ::Rails.application.routes.url_helpers.code_image_comercio_servicio_url({ :id => producto.id, :host => C.shop_url})
    #:Waba::Transaccion.new(:cliente).enviar_url( fono, url_de_producto)

    linea.info "En Transaction enviar_vale_de_mensajeria"

    body= {
        "messaging_product" => "whatsapp",
        "to"                => to_fono,
        "type"              => "template",
        "template"          => {
          "name"            => "vale_de_mensajeria",
          "language"        => {
            "code"          => "es"
          },
        "components"        => [
          { "type"          => "header", "parameters" => [
          { "type"          => "image",
            "image"          => { "link" => url_de_producto } } ] },
          { "type"          => "body",
            "parameters" => [
          { "type"          => "text",
            "text"          => presupuesto.name },
          { "type"          => "text",
            "text"          => presupuesto.fono   },
          { "type"          => "text",
            "text"          => presupuesto.comuna },
          { "type"          => "text",
            "text"          => presupuesto.direccion },
          { "type"          => "text",
            "text"          => producto.nombre  },
          { "type"          => "text",
            "text"          => "#{carga.cantidad}X#{producto.precio}"  },
          { "type"          => "text",
            "text"          => producto.moneda  },
          { "type"          => "text",
            "text"          => producto.mensajeria.nil? ? 'a convenir' : producto.mensajeria  },
          { "type"          => "text",
            "text"          => producto.moneda_mensajeria } ,
          { "type"          => "text",
            "text"          => carga.cantidad * (producto.precio - producto.comision) } , 
          { "type"          => "text",
            "text"          => producto.moneda }, 
         { "type"           => "text",
           "text"           => "#{carga.cantidad}X#{producto.comision}" },
         { "type"           => "text",
           "text"           => producto.moneda_comision },   
         { "type"           => "text",
           "text"           => "https://chat.whatsapp.com/DsaZ98eEpslCou8kFU92mg" }           
            ]}]}}



    if send body, presupuesto
      return true
    else
      return false
    end

  end





  #Cuando no estoy al día en los pagos de facebook no se envía
  def enviar_vale_de_mensajeria( presupuesto, producto, fono=nil )

    #Si se indica un fono, usar ese fono
    #Si no se indica un fono, usar el fono del usuario de ese presupuesto
    #Si es test, usar el fono del usuario de test
    if fono.nil?
      usuario = presupuesto.usuario
      nombre  = usuario.nombre
      #fono    = "#{usuario.fono}" 
    else
      fono    = C.fono_test if Rails.env.test?
      user = ::User.find_by(:fono => fono)
      nombre = user.name
    end

   #auth_token = ::Waba::Transaccion.new(:admin).autoriza( usuario)
   #url_de_pago="#{C.api_url}/api/v1/electrico/presupuestos/#{presupuesto.remember_token}/pagar_oferta/?auth_token=#{auth_token}"
   #::Waba::Transaccion.new(:cliente).enviar_url( fono, url_de_pago)

    url_de_producto = ::Rails.application.routes.url_helpers.code_image_comercio_servicio_url({ :id => producto.id, :host => C.shop_url})
    #:Waba::Transaccion.new(:cliente).enviar_url( fono, url_de_producto)


    linea.info "En Transaction enviar_vale_de_mensajeria"

    body= {
        "messaging_product" => "whatsapp",
        "to"                => fono,
        "type"              => "template",
        "template"          => {
          "name"            => "vale_de_mensajeria",
          "language"        => {
            "code"          => "es"
          },
        "components"        => [
          { "type"          => "header", "parameters" => [
          { "type"          => "image",
            "image"          => { "link" => url_de_producto } } ] },
          { "type"          => "body", "parameters" => [
          { "type"          => "text",
            "text"          => nombre },
          { "type"          => "text",
            "text"          => fono   },
          { "type"          => "text",
            "text"          => presupuesto.fecha_visita.to_datetime.strftime("%Y-%m-%d" ) } ,
          { "type"          => "text",
            "text"          => presupuesto.comuna },
          { "type"          => "text",
            "text"          => presupuesto.direccion },
          { "type"          => "text",
            "text"          => producto.nombre  },
          { "type"          => "text",
            "text"          => producto.moneda },
          { "type"          => "text",
            "text"          => producto.precio  },
          { "type"          => "text",
            "text"          => "precio"  },
          { "type"          => "text",
            "text"          => "precio"  },
          { "type"          => "text",
            "text"          => "precio"  }
            
            ]
         }]}
       }



    if send body, presupuesto
      return true
    else
      return false
    end

  end


  #no ha sido probabada bien. PEro podría usarse como fallback cuando no tenga cŕeditos en facebook
  def enviar_vale_de_mensajeria_version_interactive( presupuesto, producto, fono=nil)

    #Si es test, usar el fono del usuario de test
    if fono.nil?
      usuario = presupuesto.usuario
      nombre  = usuario.nombre
      fono    = "#{usuario.fono}"
    else
      fono    = C.fono_test if Rails.env.test?
      user = ::User.find_by(:fono => fono)
      nombre = user.name
    end

   #auth_token = ::Waba::Transaccion.new(:admin).autoriza( usuario)
   #url_de_pago="#{C.api_url}/api/v1/electrico/presupuestos/#{presupuesto.remember_token}/pagar_oferta/?auth_token=#{auth_token}"
   #::Waba::Transaccion.new(:cliente).enviar_url( fono, url_de_pago)

    url_de_producto = ::Rails.application.routes.url_helpers.code_image_comercio_servicio_url({ :id => producto.id, :host => C.shop_url})
    #:Waba::Transaccion.new(:cliente).enviar_url( fono, url_de_producto)


    linea.info "En Transaction enviar_vale_de_mensajeria"

      body = {
          "messaging_product"       => "whatsapp",
          "recipient_type"          => "individual",
          "to"                      => fono,
          "type"                    => "interactive",
          "interactive" => {
            "type"                  => "list",
            "header"                => {
              "type"                => "text",
              "text"                => "Editar Presupuesto"
            },
            "body"                  => {
              "text"                => "Presione 'DETALLE' para editar los campos de este presupuesto."
            },
            "footer"                => {
              "text"                => "alectrico ®"
            },
            "action"                => {
              "button"              => "DETALLE",
            "sections"            => [
                {
                  "title"           => "SOLICITUD",
                  "rows"            => [
                    {
                      "id"          => presupuesto.id,
                      "title"       => "Problema reportado:",
                      "description" => ( presupuesto&.descripcion ? presupuesto.descripcion.strip.truncate(70) : 'Describa el problema eléctrico.')
                    },
                    {
                      "id"          => presupuesto.id+1,
                      "title"       => "Usuario:",
                      "description" => presupuesto&.usuario&.nombre&.strip&.truncate(70)
                    },
                    {
                      "id"          => presupuesto.id+2,
                      "title"       => "Fono del Usuario:",
                      "description" => "#{presupuesto&.usuario&.fono}"
                    },
                    {
                      "id"          => presupuesto.id+3,
                      "title"       => "Email del Usuario:",
                      "description" => presupuesto&.usuario&.email&.truncate(70)
                    },
                    {
                      "id"          => presupuesto.id+4,
                      "title"       => "Dirección:",
                      "description" => (presupuesto&.direccion ? presupuesto.direccion.strip.truncate(70) :  'Indique una dirección')
                    },
                    {
                      "id"          => presupuesto.id+5,
                      "title"       => "Usuario confirmado?",
                      "description" => ( presupuesto&.usuario&.user&.confirmed_at.nil? ? "No" : "Sí")
                    },
                    {
                      "id"          => presupuesto.id+6,
                      "title"       => "Comuna",
                      "description" => presupuesto&.comuna
                    }
                  ]
                },
                {
                  "title"           => "MONTOS",
                  "rows"            => [
                    {
                      "id"          => presupuesto.id+6,
                      "title"       => "Precio",
                      "description" => presupuesto.precio.nil? ? 0 : presupuesto.precio
                    },
                    {
                      "id"          => presupuesto.id+7,
                      "title"       => "Lo cobrado",
                      "description" => presupuesto.lo_cobrado.nil? ? 0 : presupuesto.lo_cobrado
                    }
                  ]
                }
              ]
            }
          }
        }

      if send body
        return true
      else
        return false
      end
    end


    def edita_presupuesto( presupuesto, fono)

      body = {
          "messaging_product"       => "whatsapp",
          "recipient_type"          => "individual",
          "to"                      => fono,
          "type"                    => "interactive",
          "interactive" => {
            "type"                  => "list",
            "header"                => {
              "type"                => "text",
              "text"                => "Editar Presupuesto"
            },
            "body"                  => {
              "text"                => "Presione 'DETALLE' para editar los campos de este presupuesto."
            },
            "footer"                => {
              "text"                => "alectrico ®"
            },
            "action"                => {
              "button"              => "DETALLE",
              "sections"            => [
                {
                  "title"           => "SOLICITUD",
                  "rows"            => [
                    {
                      "id"          => presupuesto.id,
                      "title"       => "Problema reportado:",
                      "description" => ( presupuesto&.descripcion ? presupuesto.descripcion.strip.truncate(70) : 'Describa el problema eléctrico.')
                    },
                    {
                      "id"          => presupuesto.id+1,
                      "title"       => "Usuario:",
                      "description" => presupuesto&.usuario&.nombre&.strip&.truncate(70)
                    },
                    {
                      "id"          => presupuesto.id+2,
                      "title"       => "Fono del Usuario:",
                      "description" => "#{presupuesto&.usuario&.fono}"
                    },
                    {
                      "id"          => presupuesto.id+3,
                      "title"       => "Email del Usuario:",
                      "description" => presupuesto&.usuario&.email&.truncate(70)
                    },
                    {
                      "id"          => presupuesto.id+4,
                      "title"       => "Dirección:",
                      "description" => (presupuesto&.direccion ? presupuesto.direccion.strip.truncate(70) :  'Indique una dirección')
                    },
                    {
                      "id"          => presupuesto.id+5,
                      "title"       => "Usuario confirmado?",
                      "description" => ( presupuesto&.usuario&.user&.confirmed_at.nil? ? "No" : "Sí")
                    },
                    {
                      "id"          => presupuesto.id+6,
                      "title"       => "Comuna",
                      "description" => presupuesto&.comuna
                    }
                  ]
                },
                {
                  "title"           => "MONTOS",
                  "rows"            => [
                    {
                      "id"          => presupuesto.id+6,
                      "title"       => "Precio",
                      "description" => presupuesto.precio.nil? ? 0 : presupuesto.precio
                    },
                    {
                      "id"          => presupuesto.id+7,
                      "title"       => "Lo cobrado",
                      "description" => presupuesto.lo_cobrado.nil? ? 0 : presupuesto.lo_cobrado
                    }
                  ]
                }
              ]
            }
          }
        }

    if send body
      return true
    else
      return false
    end
  end




  def enviar_presupuesto(gestor, presupuesto)

      fono = "#{gestor.fono}"
      fono = C.fono_test if Rails.env.test?

      body = {
          "messaging_product"       => "whatsapp",
          "recipient_type"          => "individual",
	  "to"                      => fono,
          "type"                    => "interactive",
          "interactive" => {
            "type"                  => "list",
            "header"                => {
              "type"                => "text",
              "text"                => gestor.name.strip.truncate(50).upcase
            },
            "body"                  => {
              "text"                => "Alguien lo necesita para concretar o cerrar una venta. Presione 'DETALLE' más abajo si desea saber de qué se trata."
            },
            "footer"                => {
              "text"                => "alectrico ®"
            },
            "action"                => {
              "button"              => "DETALLE",
              "sections"            => [
                {
                  "title"           => "SOLICITUD",
                  "rows"            => [
                    {
                      "id"          => presupuesto.id,
                      "title"       => "Problema reportado:",
                      "description" => presupuesto.descripcion.strip.truncate(70)
                    },
                    {
                      "id"          => presupuesto.id+1,
                      "title"       => "Usuario:",
                      "description" => presupuesto.usuario.nombre.strip.truncate(70)
                    },
                    {
                      "id"          => presupuesto.id+2,
                      "title"       => "Fono del Usuario:",
		      "description" => "#{presupuesto.usuario.fono}"
                    },
                    {
                      "id"          => presupuesto.id+3,
                      "title"       => "Email del Usuario:",
                      "description" => presupuesto.usuario.email.truncate(70)
                    },
                    {
                      "id"          => presupuesto.id+4,
                      "title"       => "Dirección",
                      "description" => ( presupuesto.direccion.nil? ? " " : presupuesto.direccion.strip.truncate(70))
                    },
                    {
                      "id"          => presupuesto.id+5,
                      "title"       => "Usuario confirmado?",
                      "description" => ( presupuesto.usuario&.user&.confirmed_at.nil? ? "No" : "Sí")
                    },
                    {
                      "id"          => presupuesto.id+5,
                      "title"       => "Comuna",
                      "description" => presupuesto.comuna
                    }
                  ]
                },
                {
                  "title"           => "MONTOS",
                  "rows"            => [
                    {
                      "id"          => presupuesto.id+6,
                      "title"       => "Precio",
                      "description" => presupuesto.precio.nil? ? 0 : presupuesto.precio
                    },
                    {
                      "id"          => presupuesto.id+7,
                      "title"       => "Lo cobrado",
                      "description" => presupuesto.lo_cobrado.nil? ? 0 : presupuesto.lo_cobrado  
                    }
                  ]
                }
              ]
            }
          }
        }

    if send body
      return true
    else
      return false
    end
  end


  #Responde a un mensaje con una id de contexto eso
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


  def enviar_url(fono, url)

    fono= "#{fono}"
    fono= C.fono_test if Rails.env.test?

    linea.info "En Transaction enviar_mensaje con url"

      body = {
          "messaging_product" =>  "whatsapp",
          "recipient_type"    =>  "individual",
          "to"                =>  fono,
          "type"              =>  "text",
          "text"              =>  { "preview_url" => true,
                                    "body" => url }
          }

    if send body
      return true
    else
      return false
    end
  end

  def enviar_ubicacion(fono, comuna, direccion)

    fono= "#{fono}"
    fono= C.fono_test if Rails.env.test?

    linea.info "En Transaction enviar_ubicacion"

      body = {
          "messaging_product" =>  "whatsapp",
          "recipient_type"    =>  "individual",
          "to"                =>  fono,
          "type"              => "location",
          "location"    =>  {
            "longitude" => -70.6083,
            "latitude"  => -33.4333,
            "name"      => comuna,
            "address"   => direccion
          }  }

    if send body
      return true
    else
      return false
    end
  end



#  "image": {
#    "link": "http(s)://the-url",
#    "provider": {
#        "name" : "provider-name"
#    }
#  }
#  
#  "image": {
#    "id": "your-media-id"   
#  }
  
#}

  def enviar_imagen(fono, usuario, imagen)
    fono= "#{fono}"
    fono= C.fono_test if Rails.env.test?
    linea.info "En Transaction enviar_imagen"
    body = {
          :messaging_product =>  "whatsapp",
          :to                =>  fono,
          :type              =>  "template",
          :template          => {
            :name            =>   "imagen",
            :language        => { "code" => "es" },
          :components        => [
            { :type          =>   "header", "parameters" => [
            { :type          =>   "image",
              :image         => { "id" => imagen.id } } ] },
            { :type          =>   "body", "parameters" => [
            { :type          =>   "text",
              :text          =>   imagen.caption },
            { :type          =>   "text",
              :text          =>   usuario.nombre } ] }   ]}}
    if send body
      return true
    else
      return false
    end
  end

  def enviar_video(fono, presupuesto, video)
    fono= "#{fono}"
    fono= C.fono_test if Rails.env.test?

    linea.info "En Transaction enviar_video"

   #el template es video para
    #del waba publico colaboradores
    #usa un formulario que no funciona
    #da error 500 en facebook
    #uno de los waba
    body = {
          "messaging_product" =>  "whatsapp",
          "to"                =>  fono,
          "type"              =>  "template",
          "template"          => {
            "name"            =>   "video_simple",
            "language"        => { "code" => "es" },
          "components"        => [
            { "type"          =>   "header", "parameters" => [
            { "type"          =>   "video",
              "video"         => { "id" => video.id } } ] },
            { "type"          =>   "body", "parameters" => [
            { "type"          =>   "text",
              "text"          =>   video.caption },
            { "type"          =>   "text",
              "text"          =>   presupuesto.id },
            { "type"          =>   "text",
              "text"          =>   presupuesto.usuario.nombre } ] }
           ]}}


    if send body
      return true
    else
      return false
    end
  end

  

  def enviar_imagen_by_link(fono, imagen_link)
    fono= "#{fono}"
    fono= C.fono_test if Rails.env.test?

    linea.info "En Transaction enviar_mensaje_by_link"

      body = {
          "messaging_product" =>  "whatsapp",
          "recipient_type"    =>  "individual",
          "to"                =>  fono,
          "type"              =>  "image",
          "image"              =>  { "link" => imagen_link}
          }

    if send body
      return true
    else
      return false
    end
  end

  def enviar_imagen_by_id(fono, imagen_id)
    fono= "#{fono}"
    fono= C.fono_test if Rails.env.test?

    linea.info "En Transaction enviar_mensaje_by_id"

      body = {
          "messaging_product" =>  "whatsapp",
          "recipient_type"    =>  "individual",
          "to"                =>  fono,
          "type"              =>  "image",
          "image"              =>  { "id" => imagen_id }
          }

    if send body
      return true
    else
      return false
    end
  end


  def enviar_contacto(fono, user)

    fono= "#{fono}"
    fono= C.fono_test if Rails.env.test?
    linea.info "En Transaction enviar_contacto"

      body = {
          "messaging_product"    => "whatsapp",
          "recipient_type"       => "individual",
          "to"                   => fono,
          "type"                 => "contacts",
          "contacts"             => [{
              "emails"           => [{
                "email"          => user.email,
                  "type"         => "Trabajo"
                }],
            "phones"             => [{
                  "phone"        => user.fono,
                  "type"         => "Personal",
                  "wa_id"        => user.fono,
            }],
              "name"             => {
                 "formatted_name" => user.name,
                 "first_name"     => user.name
              }}]}

    if send body
      return true
    else
      return false
    end

  end

  def enviar_contacto_alec(fono)

    fono= "#{fono}"
    fono= C.fono_test if Rails.env.test?
    linea.info "En Transaction enviar_contactos"

      body = {
          "messaging_product"    => "whatsapp",
          "recipient_type"       => "individual",
          "to"                   => fono,
          "type"                 => "contacts",
          "contacts"             => [{
              "emails"           => [{
                "email"          => "alec@alectrico.cl",
                  "type"         => "Trabajo"
                }],
            "phones"             => [{
                  "phone"        => C.display_phone_number_colaboradores,
                  "type"         => "Personal",
                  "wa_id"        => C.display_phone_number_colaboradores,
            }],
            "org"              => {
                "company"        => "alectrico SpA",
                "department"     => "Asistencia Técnica",
                "title"          => "alec"
              },
            "urls"             => [{
                  "url"          => "https://alectrico.cl",
                  "type"         => "Presentación"
                },
                {
                  "url"          => "https://wwww.alectrica.cl/agendar",
                  "type"         => "Sitio de Pedidos"
               }],
              "name"             => {
                "formatted_name" => "alec: asistente alectrico®",
                "first_name"     => "alec"
              }}]}

    if send body
      return true
    else
      return false
    end

  end


   def enviar_contacto_alectrico(fono)

    fono= "#{fono}"
    fono= C.fono_test if Rails.env.test?

#               "birthday"           => "1967-01-20",

    linea.info "En Transaction enviar_contactos"

      body = {
          "messaging_product"    => "whatsapp",
          "recipient_type"       => "individual",
          "to"                   => fono,
          "type"                 => "contacts",
          "contacts"             => [{
              "emails"           => [{
                "email"          => "ventas@alectrico.cl",
                  "type"         => "Trabajo"
                }],
            "phones"             => [{
                  "phone"        => "56932000849",
                  "type"         => "Personal",
                  "wa_id"        => "56932000849"
            }],
            "org"              => {
                "company"        => "alectrico SpA",
                "department"     => "Gerencia",
                "title"          => "CREO"
              },
            "urls"             => [{
                  "url"          => "https://alectrico.cl",
                  "type"         => "Plataforma digital"
                },
                {
                  "url"          => "https://repair.alectrico.cl",
                  "type"         => "Sitio de Pedidos"
               }],
              "name"             => {
                "formatted_name" => "Ing. Alexander Espinosa MEng.",
                "first_name"     => "Alexander"
              }}]}

    if send body
      return true
    else
      return false
    end

  end

  #Envío sin template
  #Se podría usar para enviar una colección de documentos
  def enviar_documento(   link,   filename,    fono   )

    linea.info "En Transaction enviar_documento de Waba"

    fono = "#{fono}"
    fono = C.fono_test if Rails.env.test?

      body =  {
        :messaging_product => "whatsapp",
        :recipient_type    => "individual",
        :to                => fono,
        :type              => "document", 
        :document          =>
        { :link            => "#{link}", 
          :filename        => "#{filename}" }}


    if send body
      return true
    else
      return false
    end

  end



  #envia circuitos pdf a quienquiera que lo necesite
  #aunque el presupuestono tenga colaborador
  #ni usuario
  #Toma la ruta de los circuitos de un presupuesto con id 
  #con el formato pdf y lo envía por whatsapp
  #Le envía un link al usuario del presupuesto
  #par que baje los circuitos
  #esto se invoca en Bajar pdf en la etapa circuitos de presupuesto
  def enviar_circuitos_pdf_libre( presupuesto, fono, nombre_destinatario, nombre_remitente)
    #es libre porque no requiere auth_token y tampoco verifica el usuario
    #el pdf tambíen se puede bajar libremente desde api/v1/electrico/presupuestos/download_unilineal_pdf
    linea.info "En Transaction enviar_circuito_pdf_libre de WABA"

  # return false if not presupuesto.usuario.present?

 #   valid_payload = {'user'=>{'email' => presupuesto.usuario.email}}
#   coded_token   = JsonWebToken.encode(:reader => valid_payload )
   #no he podido probar esta versión, usa auth_token
   #url_del_archivo =   Rails.application.routes.url_helpers.download_circuitos_pdf_api_v1_electrico_presupuesto_url(:id => presupuesto.remember_token, :host =>  C.api_subdomain + '.' + C.dominio, :protocol => 'https', :params => {:auth_token => coded_token} )
    url_del_archivo =   Rails.application.routes.url_helpers.download_unilineal_pdf_api_v1_electrico_presupuesto_url(
      :format => :pdf,
      :id => presupuesto.id, 
      :host =>  C.api_subdomain + '.' + C.dominio, 
      :protocol => 'https', 
      :params => {:id => presupuesto.id} )


    titulo_del_archivo  =  "circuitos_del_presupuesto_#{presupuesto.id}.pdf"

    fono = C.fono_test if Rails.env.test?

    body =  {
        messaging_product: "whatsapp",
                       to: fono,
                     type: "template",
                 template: { name: "envio_de_documento", language: { code: "es" },
            components: [
        { type: "header",
          parameters: [
              { type: "document",
            document: { link: "#{url_del_archivo}",
            filename: titulo_del_archivo }}]},
        { type: "body"  , parameters: [ { type: "text", text: "#{nombre_destinatario}" },
                                        { type: "text", text: "El archivo será bajado con el nombre: #{titulo_del_archivo}. Debe dejar pasar unos diez segundos para que pueda leerlo. También puede imprimirlo usando la app Mobile Print de Samsung." },
                                        { type: "text", text: "#{nombre_remitente.nil? ? nombre_remitente : '_' }" },
                { type: "text", text: "Contiene: El Diagrama Unilineal con los circuitos que necesita su instalación eléctrica. Es un documento de trabajo, no una certificación. La palabra final la tendrá el TE1 firmado por un Instalador Eléctrico Autorizado SEC." }]}]}}


    if send body, presupuesto
      return true
    else
      linea.warn "Error enviando documento circuitos_pdf por WABA a #{nombre_destinatario} al #{fono}"
      return false
    end

  end




  #Toma la ruta de los circuitos de un presupuesto con id 
  #con el formato pdf y lo envía por whatsapp
  #Le envía un link al usuario del presupuesto
  #par que baje los circuitos
  #esto se invoca en Bajar pdf en la etapa circuitos de presupuesto
  def enviar_circuitos_pdf( presupuesto )

    linea.info "En Transaction enviar_circuito_pdf de WABA"

  #  return false if not presupuesto.colaborador.present?

    valid_payload = {'user'=>{'email' => presupuesto.usuario.email}}
    coded_token   = JsonWebToken.encode(:reader => valid_payload )

#                                       presupuesto_circuitos GET    /presupuestos/:presupuesto_id/circuitos(.:format)                                                 electrico/circuitos#index
    url_del_archivo =   Rails.application.routes.url_helpers.download_circuitos_pdf_api_v1_electrico_presupuesto_url(:id => presupuesto.remember_token, :host =>  C.api_subdomain + '.' + C.dominio, :protocol => 'https', :params => {:auth_token => coded_token} )

    titulo_del_archivo  =  "circuitos_del_presupuesto_#{presupuesto.id}.pdf"

    if presupuesto.usuario
      nombre_del_cliente  =  presupuesto.usuario.nombre
      fono_del_cliente    =  presupuesto.usuario.fono
    else
      user = ::User.find_by(:fono => presupuesto.fono)
      nombre_del_cliente  = user.name
      fono_del_cliente    = user.fono
    end
    
    fono_del_cliente    = "#{fono_del_cliente}"
    fono_del_cliente = C.fono_test if Rails.env.test?


    body =  {
        messaging_product: "whatsapp",
                       to: fono_del_cliente,
                     type: "template",
                 template: { name: "envio_de_documento", language: { code: "es" },
            components: [
        { type: "header",
          parameters: [
              { type: "document",
            document: { link: "#{url_del_archivo}",
            filename: titulo_del_archivo }}]},
        { type: "body"  , parameters: [ { type: "text", text: "#{nombre_del_cliente}" },
                                        { type: "text", text: "El archivo será bajado con el nombre: #{titulo_del_archivo}. Debe dejar pasar unos diez segundos para que pueda leerlo. También puede imprimirlo usando la app Mobile Print de Samsung." },
                { type: "text", text: "#{presupuesto.colaborador&.usuario&.nombre} - Colaborador Independiente" },
                { type: "text", text: "Contiene: El Diagrama Unilineal con los circuitos que necesita su instalación eléctrica. Es un documento de trabajo, no una certificación. La palabra final la tendrá el TE1 firmado por un Instalador Eléctrico Autorizado SEC." }]}]}}


    if send body, presupuesto
      return true
    else
      linea.warn "Error enviando documento circuitos_pdf por WABA a #{nombre_del_cliente} al #{fono_del_cliente}"
      return false
    end

  end


  def enviar_levantamiento_pdf( levantamiento, contenido )

    presupuesto = levantamiento.presupuesto
    linea.info "En Transaction enviar_levantamiento_pdf de WABA"

    valid_payload = {'user'=>{'email' => presupuesto.usuario.email}}
    coded_token   = JsonWebToken.encode(:reader => valid_payload )

    url_del_archivo =   Rails.application.routes.url_helpers.download_levantamiento_pdf_api_v1_electrico_presupuesto_url(:levantamiento_id => levantamiento.id,:id => presupuesto.remember_token, :host =>  C.api_subdomain + '.' + C.dominio, :protocol => 'https', :params => {:auth_token => coded_token} )

    titulo_del_archivo  =  "levantamiento_#{levantamiento.id}.pdf"
    nombre_del_cliente  =  presupuesto.usuario.nombre
    fono_del_cliente    =  presupuesto.usuario.fono

    fono_del_cliente    = "#{fono_del_cliente}"
    fono_del_cliente = C.fono_test if Rails.env.test?


    body =  {
        messaging_product: "whatsapp",
                       to: fono_del_cliente,
                     type: "template",
                 template: { name: "envio_de_documento", language: { code: "es" },
            components: [
        { type: "header",
          parameters: [
              { type: "document",
            document: { link: "#{url_del_archivo}",
            filename: titulo_del_archivo }}]},
        { type: "body"  , parameters: [ { type: "text", text: "#{nombre_del_cliente}" },
                                        { type: "text", text: "El archivo será bajado con el nombre: #{titulo_del_archivo}. Debe dejar pasar unos diez segundos para que pueda leerlo. También puede imprimirlo usando la app Mobile Print de Samsung." },
                                        { type: "text", text: "#{levantamiento.presupuesto.colaborador.usuario.nombre} - Colaborador Indepediente" },
                { type: "text", text: "Contiene: #{contenido}." }]}]}}


    if send body, presupuesto
      return true
    else
      linea.warn "Error enviando documento circuitos_pdf por WABA a #{nombre_del_cliente} al #{fono_del_cliente}"
      return false
    end

  end



  #Esto envía un presupuesto securitizado con un token
  #Está en uso solo para alectrico
  #No envía link de pago
  def enviar_presupuesto_pdf( presupuesto )

    linea.info "En Transaction enviar_presupuesto_pdf de WABA"

    #return false if not presupuesto.colaborador.present?

    valid_payload = {'user'=>{'email' => presupuesto.usuario.email}}
    coded_token   = JsonWebToken.encode(:reader => valid_payload )

    url_del_archivo =   Rails.application.routes.url_helpers.download_pdf_api_v1_electrico_presupuesto_url(:id => presupuesto.remember_token, :host =>  C.api_url, :protocol => 'https', :format => 'pdf', :params => {:auth_token => coded_token} )

    titulo_del_archivo  =  "alectric®presupuesto_#{presupuesto.id}.pdf" 
    nombre_del_cliente  =  presupuesto.usuario.nombre
    fono_del_cliente    =  presupuesto.usuario.fono

    fono_del_cliente    = "#{fono_del_cliente}"
    fono_del_cliente = C.fono_test if Rails.env.test?


    body =  {
        messaging_product: "whatsapp",
                       to: fono_del_cliente,
                     type: "template",
                 template: { name: "envio_de_documento", language: { code: "es" },
            components: [
        { type: "header",
          parameters: [
              { type: "document",
            document: { link: "#{url_del_archivo}",
            filename: titulo_del_archivo }}]},
        { type: "body"  , parameters: [ { type: "text", text: "#{nombre_del_cliente}" },
                                        { type: "text", text: "El archivo será bajado con el nombre: #{titulo_del_archivo}. Debe dejar pasar unos diez segundos para que pueda leerlo. Tambíén puede imprimirlo usando la app Mobile Printer de Samsung."},
                { type: "text", text: "#{presupuesto.colaborador.usuario.nombre} - Colaborador Independiente" },
                { type: "text", text: "Contiene: El presupuesto para la reparación de su instalación eléctrica."  }]}]}}


    if send body, presupuesto
      return true
    else
      linea.warn "Error enviando documento presupuesto.pdf por WABA a #{nombre_del_cliente} al #{fono_del_cliente}"
      return false
    end

  end


  def say_toma_1( colaborador,  presupuesto )

    linea.info presupuesto.inspect

    comuna         = presupuesto.comuna
    sintoma        = presupuesto.descripcion
    presupuesto_id = presupuesto.id

    fono = "#{colaborador.fono}"
    fono = C.fono_test if Rails.env.test?

    linea.info "En Transaction.say_toma"
      body_recargar = {
          "messaging_product" =>  "whatsapp",
          "to"                =>  fono,
          "type"              =>  "template",
          "template"          => {
            "name"            =>   "recargar",
            "language"        => { "code" => "es" },
          :components         => [
            { "type"          =>   "header", "parameters" => [
            { "type"          =>   "image",
              "image"          => { "link" => WabaCfg.image_url_say_ofertar } } ] },
            { "type"          =>   "body", "parameters" => [
            { "type"          =>   "text",
              "text"          =>   colaborador.name.upcase_first     } ] }
           ]}}


    body_say_toma = {"messaging_product": "whatsapp",
      "to": fono,
      "type": "template",
      "template": {
        "name": "nuevo_servicio",
        "language": { "code": "es_AR" },
        "components": [ { "type": "header",  "parameters": [
      { "type": "text",  "text": "#{comuna.upcase}" } ] },
      { "type": "body",    "parameters": [
      { "type": "text",  "text": "#{colaborador.name.upcase_first}" } ,
      { "type": "text",  "text": "#{sintoma.upcase_first}" },
      { "type": "text",  "text": "#{comuna.upcase_first}" } ] } ,
      { "type": "button","sub_type": "url","index":"0",
        "parameters": [  { "type": "text",
        "text": "/electrico/presupuestos/#{presupuesto_id}/aceptar_contrato_y_tomar_presupuesto" } ] } ] } }

   
    body = body_recargar

    if send body
      return true
    else
      return false
    end

  end

  def download_media( url )
  #  obtiene una representación binaria
 # curl  \
 #'URL' \
 #-H 'Authorization: Bearer ACCESS_TOKEN' > media_file
    headers = { Authorization: "Bearer #{@token}"}
    request = ::Typhoeus::Request.new(
      url,
      method: :get,
      headers: headers
    )

    request.on_complete do |response|
      linea.info response.inspect
      body = response.options[:response_body]
      if response.success?
        body = response.options[:response_body]
        jbody = JSON.parse(body)
     #   url   = jbody['url']
        return jbody
        # hell yeah
      elsif response.timed_out?
        # aw hell no
        return false
      elsif response.code == 0
        # Could not get an http response, something's wrong.
        return false
      else
        # Received a non-successful http response.
        linea.info "HTTP request failed: " + response.code.to_s
        return false
      end
    end

    request.run

  end


  def retrieve_media( media_id )
    url = "https://graph.facebook.com/v18.0/#{media_id}/" 
    headers = { Authorization: "Bearer #{@token}"}

    request = ::Typhoeus::Request.new(
      url,
      method: :get,
      headers: headers
    )

    request.on_complete do |response|
      linea.info response.inspect
  #    :response_body=>"{\"url\":\"https:\\/\\/lookaside.fbsbx.com\\/whatsapp_business\\/attachments\\/?mid=1279872089367697&ext=1697916995&hash=ATuoS5Vgwprw0GjsuvO_CvQ4BzEDvrM7mSJyvCZV2Jhi9g\",\"mime_type\":\"image\\/jpeg\",\"sha256\":\"d48a6ea3022606e7e4e33cfa827b5452d4ee8ca3810dd9312290da638b5f8b13\",\"file_size\":25950,\"id\":\"1279872089367697\",\"messaging_product\":\"whatsapp\"}", :debug_info=>#<Ethon::Easy::DebugInfo:0x0000297dd79ed260 @messages=[]>
        body = response.options[:response_body]
 #      {
 #"messaging_product": "whatsapp",
 #"url": "<URL>",
 #"mime_type": "<MIME_TYPE>",
 #"sha256": "<HASH>",
 #"file_size": "<FILE_SIZE>",
 #"id": "<MEDIA_ID>"
#}
      if response.success?
        body = response.options[:response_body]
        jbody = JSON.parse(body)
        url   = jbody['url']
        return url
        # hell yeah
      elsif response.timed_out?
        # aw hell no
        return false
      elsif response.code == 0
        # Could not get an http response, something's wrong.
        return false
      else
        # Received a non-successful http response.
        linea.info "HTTP request failed: " + response.code.to_s
        return false
      end
    end

    request.run

  end

  def test_typhoeus

    url_de_pago="api/v1/electrico/presupuestos/1/pagar/?auth_token=1"

    grafica="https://www.alectrico.cl/img/master_picture.png"

    headers = {"Content-Type": "application/json", Authorization: "Bearer #{@token}"}

    body    = {
              "messaging_product": "whatsapp",
              "to": C.fono_test,
              "type": "template",
              "template": {
                "name": "saludo",
                "language": {
                  "code": "es_AR"},
  "components": [
    { "type": "header", "parameters": [ { "type": "image",
                          "image": { "link": "#{grafica}" } } ] },
    { "type": "body"  , "parameters": [ { "type": "text", "text": "huano" },
                                        { "type": "text", "text": "se me cortó el teléfono" } ] },
    { "type": "button", "sub_type": "url", "index":"1",
      "parameters": [ { "type": "text", "text": "#{url_de_pago}" } ] } ] }}
  

    url = "#{@base_uri}/#{@api_version}/#{@waba_id}/messages"

    linea.info url

    request = ::Typhoeus::Request.new(
      url,
      method: :post,
      body: body,
      headers: headers
    )

    request.on_complete do |response|
      linea.info response.inspect
      if response.success?
        return true
        # hell yeah
      elsif response.timed_out?
        # aw hell no
        return false
      elsif response.code == 0
        # Could not get an http response, something's wrong.
        return false
      else
        # Received a non-successful http response.
        linea.info "HTTP request failed: " + response.code.to_s
        return false
      end
    end

    request.run

  end


  def say_bienvenido( usuario, sintoma, presupuesto_token)

    presupuesto = Electrico::Presupuesto.find_by(:remember_token => presupuesto_token)

    auth_token = autoriza( usuario)

    url_de_pago="api/v1/electrico/presupuestos/#{presupuesto_token}/pagar_visita/?auth_token=#{auth_token}"

    #rafica = "https://scontent.fscl12-1.fna.fbcdn.net/v/t39.82-6/2447736_204685541637918_5359465827721283394_n.jpg?_nc_cat=100&ccb=1-7&_nc_sid=ad8a9d&_nc_eui2=AeHN1WW6Ve04bDGIUGZPv0XzAKlFIkvSheUAqUUiS9KF5ZKTXCftoeUS-C103ITjTpxxu2COLHBPOlOZATJZsDuT&_nc_ohc=yMwxIw3t6w8AX94KGFI&_nc_ht=scontent.fscl12-1.fna&oh=00_AT_y2khLXuhdu53YXlqeSIvJpnI5MLSXQ0auFpGQ7RcM5w&oe=62AB35D9"
     # grafica="https://alectrico.cl/assets/images/wp-20160621-7-14x2592-800x1424.jpg"
    #
   grafica = WabaCfg.image_url_say_bienvenido  # https://www.alectrica.cl/img/farol.jpg

   # grafica="https://www.alectrico.cl/img/master_picture.png"

    headers = {"Content-Type": "application/json", Authorization: "Bearer #{@token}"}

    body    = {
              "messaging_product": "whatsapp",
              "to": "#{usuario.fono}",
              "type": "template",
              "template": { "name": "saludo", "language": {"code": "es"},
  "components": [
    { "type": "header", "parameters": [ { "type": "image",
                          "image": { "link": "#{grafica}" } } ] },
    { "type": "body"  , "parameters": [ { "type": "text", "text": "#{usuario.nombre}" },
                                        { "type": "text", "text": "#{sintoma}" } ] },
    { "type": "button", "sub_type": "url", "index":"1",
      "parameters": [ { "type": "text", "text": "#{url_de_pago}" } ] } ] }}
    ##Ojo, url de pago se complementa con url en la plantilla. Hay que modificarla cada vez que se cambie el domino
    #la plantilla es saludo, con language es. Corresponde a waba de cliente 932000849


    if send body, presupuesto
      return true
    else
      return false
    end

  end

  #es para que el usuario oferte
  def say_ofertar( usuario, sintoma, presupuesto_token)
    #Este es un link de pago que se le envía al usuario para que pague en alectrico

    presupuesto = Electrico::Presupuesto.find_by(:remember_token => presupuesto_token)

    auth_token = autoriza( usuario)

    url_de_pago_de_ofertar="api/v1/electrico/presupuestos/#{presupuesto_token}/pagar_oferta/?auth_token=#{auth_token}"

    #rafica = "https://scontent.fscl12-1.fna.fbcdn.net/v/t39.82-6/2447736_204685541637918_5359465827721283394_n.jpg?_nc_cat=100&ccb=1-7&_nc_sid=ad8a9d&_nc_eui2=AeHN1WW6Ve04bDGIUGZPv0XzAKlFIkvSheUAqUUiS9KF5ZKTXCftoeUS-C103ITjTpxxu2COLHBPOlOZATJZsDuT&_nc_ohc=yMwxIw3t6w8AX94KGFI&_nc_ht=scontent.fscl12-1.fna&oh=00_AT_y2khLXuhdu53YXlqeSIvJpnI5MLSXQ0auFpGQ7RcM5w&oe=62AB35D9"
     # grafica="https://alectrico.cl/assets/images/wp-20160621-7-14x2592-800x1424.jpg"
    #
   grafica = WabaCfg.image_url_say_bienvenido  # https://www.alectrico.cl/img/farol.jpg

   # grafica="https://www.alectrico.cl/img/master_picture.png"

    headers = {"Content-Type": "application/json", Authorization: "Bearer #{@token}"}

    body    = {
              "messaging_product": "whatsapp",
              "to": "#{usuario.fono}",
              "type": "template",
              "template": { "name": "saludo", "language": {"code": "es_AR"},
  "components": [
    { "type": "header", "parameters": [ { "type": "image",
                          "image": { "link": "#{grafica}" } } ] },
    { "type": "body"  , "parameters": [ { "type": "text", "text": "#{usuario.nombre}" },
                                        { "type": "text", "text": "#{sintoma}" } ] },
    { "type": "button", "sub_type": "url", "index":"1",
      "parameters": [ { "type": "text", "text": "#{url_de_pago_de_ofertar}" } ] } ] }}



    if send body, presupuesto
      return true
    else
      return false
    end

  end


  #No estoy usando esto, solo uso el acces token como Bearer Token en los http requests.
  #Esto devuelve un token de acceso a la app. Seguramente para usar la api de facebook
  #Para desenvolverse en facebook
  #Para la relación con los clientes necesito un token de usuario
  def get_app_access_token
    linea.info "En get_access_token"
    url = "https://graph.facebook.com/oauth/access_token?client_id=#{@ae_id}&client_secret=#{@ae_secret}&grant_type=client_credentials"
    headers = {"Content-Type": "application/json" }
    begin
      request = ::Typhoeus::Request.new(
        url,
        method: :get,
        headers: headers
      )
      request.run
    rescue StandardError => e
      linea.warn e.message
    end
    body = request.response.options[:response_body]
    jbody = JSON.parse(body)
    linea.info jbody
    linea.info jbody["access_token"]
    return jbody["access_token"]
  end


  def alarga_token
    url = "https://graph.facebook.com/#{@api_version}/oauth/access_token?grant_type=fb_exchange_token&client_id=#{@ae_id}&client_secret=#{@ae_secret}&fb_exchange_token=#{@token}"
    headers = {"Content-Type": "application/json" }
    begin
      request = ::Typhoeus::Request.new(
        url,
        method: :get,
        headers: headers
      )
      request.run
    rescue StandardError => e
      linea.warn e.message
    end

    body = request.response.options[:response_body]
    jbody = JSON.parse(body)

    begin
      @token = jbody(:token)
      puts "se alargó el token"
      puts jbody
      puts @token
    rescue StandardError => error
      linea.error error.inspect
    end

  end


  def send body, presupuesto=nil, fono=nil

    waba_orden = caller_locations.first.base_label

    # Hay que sanitizar el body
    # #\"Param text cannot have new-line\\/tab characters or more than 4 consecutive spaces\"}

    # Ingrese su solicitud\nalectrico ®: Servicios Profesionales\nhttps://alectrico.cl/
    begin
      if body.has_key?(:template)
        texto = body[:template][:components].second[:parameters].second[:text]
        texto.gsub!(/\n/,' ')
        texto.gsub!(/\t/,' ')
        texto.gsub!(/"    "/,' ')
        body[:template][:components].second[:parameters].second[:text] = texto
      end
    rescue
    end
#{:messaging_product=>"whatsapp", :to=>"56981370042", :type=>"template", :template=>{:name=>"saludo", :language=>{:code=>"es"}, :components=>[{:type=>"header", :parameters=>[{:type=>"image", :image=>{:link=>"https://www.alectrico.cl/img/farol_blanco.jpg"}}]}, {:type=>"body", :parameters=>[{:type=>"text", :text=>"Alexander Espinosa"}, {:type=>"text", :text=>"Ingrese su solicitud\nalectrico ®: Servicios Profesionales\nhttps://alectrico.cl/"}]}, {:type=>"button", :sub_type=>"url", :index=>"1", :parameters=>[{:type=>"text", :text=>"api/v1/electrico/presupuestos/PbAg4RuNfvEJwb9G4We9_w/pagar_visita/?auth_token=eyJhbGciOiJIUzI1NiJ9.eyJyZWFkZXIiOnsidXNlciI6eyJlbWFpbCI6InNhbmRib3hAYWxlY3RyaWNvLmNsIn19LCJleHAiOjE2OTc3OTI1NDh9.yCCAKpTeUctD_XHNwmXJGbF47JzQ4q7C0Qu30NHzBaw"}]}]}}:Hash):

    linea.info "Body antes de ser envíado: #{body}"
    options = { headers: @headers, body: body.to_json }
    url     = "#{@base_uri}/#{@api_version}/#{@waba_id}/messages"
    headers = {"Content-Type": "application/json" }

    request = ::Typhoeus::Request.new(
        url,
        method: :post,
        body:    body,
        headers: @headers
    )

    request.on_complete do |response|
      if Rails.env.test?
         fact = Graph::Fact.new( body.merge('id': 'any') )
         fact.monito( ::Graph::Redisfile.new )
      end
      if response.success? 
        linea.info "Envío exitoso en send"
        #avisar a los instaladors
        #Solo si el mensaje estaba asociado a algún presupuesto
        response_body = response.options[:response_body]
        linea.info "------------------------------------------------------------"
        linea.info response_body
        jbody = JSON.parse(response_body)

        unless presupuesto.nil? or jbody.nil?
          id   = jbody['messages']&.first["id"]

          if id and presupuesto 
            fact = Graph::Fact.new( body.merge('id': id) )
            fact.monito( ::Graph::Redisfile.new )
            linea.info "Tratando de vincular con algún presupuesto"
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
          avisar_a_instaladores waba_orden, presupuesto, fono, body
          return true
        end
        return true
        # hell yeah
      elsif response.timed_out?
        linea.error "Time out en send"
        # aw hell no
        return false
      elsif response.code == 0
        linea.error "Could not get an http response, something's wrong."
        return false
      else
        # Received a non-successful http response.
        linea.error "HTTP request failed: " + response.code.to_s
        linea.info response.inspect
        return false
      end
    end

    request.run

  end

  def avisar_a_instaladores waba_orden, presupuesto, fono, body

    if presupuesto
      if presupuesto&.usuario.present?
        texto_mensaje = "WABA #{waba_orden} enviado para #{User.find_by(:fono => fono)&.name} #{fono} a #{presupuesto.usuario.nombre} #{presupuesto.comuna} | #{presupuesto.descripcion}"
      else
        texto_mensaje = "WABA #{waba_orden} enviado para #{User.find_by(:fono => fono)&.name} #{fono} sin comuna | #{presupuesto.descripcion}"
      end
    end

    Instalador.all.activos.each{|instalador|
          mensaje = {
                  title:           'Aviso a Instalador',
                   body:           texto_mensaje,
                   tag:            "#{waba_orden}-presupuesto:#{fono}",
                   tipo:           'aviso_a_instalador',
                   receiver_id:    instalador.id,
                   presupuesto_id: (presupuesto.nil? ? 0 : presupuesto.id ),
                   icon:           '/img/ticket.png',
                   image:          '/img/wide-landing-04.jpg',
                   badge:          '/img/ticket.png'}  
          push_to( instalador, mensaje )
    }
  end

  #El token de waba está en @headers
  #Buscar al comienzo de ese módulo
  #Este send se puso muy complicado
  #Y es probable que sea el culpable por
  #el envío duplicado de los mensajes
  #waba
  def send_antiguo body, presupuesto=nil, fono=nil

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
      request = HTTParty.post( url, options )

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

      codigo = procesa_error(request.parsed_response, presupuesto, fono)
      linea.info "El código es: #{codigo}"
      case codigo
      when 131009
	linea.info "El código se puede deber a un número equivado, no se volverá a envia waba, pero se retornará false"
	return false
      when 190
        linea.error "El token expiró y hay que alargarlo"
	linea.info "El instalador recibirá un reporte 190"
	hash_result = ::Waba::Transaccion.new(:sistema).alarga_token
	unless hash_result.respond_to?(:access_token) and has_result.has_value?('access_token')
	  begin
	   @token = hash_result['access_token']
	   #ENV['META_USER_TOKEN']=@token 
	   linea.info "Reinteando con token alargado"
           retry		
	  rescue
	  end
	else
	  linea.error "No se pudo alargar el token"
          return false
        end
      end


      request = ::Typhoeus::Request.new(
        url,
        method: :post,
        body:    body,
        headers: @headers
      )

      intentos = 0

      request.on_complete do |response|
        if response.success?

          begin
            AGENDA<<body
          rescue StandardError => e
            linea.error e.message
          end
          linea.info "Exito enviando con Typhoeus"
          response_body = response.options[:response_body]
          linea.info "------------------------------------------------------------"
          jbody = JSON.parse(response_body)
          id   = jbody['messages'].first["id"]

          carrier = ::Electrico::Carrier.create(\
           :nombre => id, \
           :tarifa => presupuesto&.id)
          linea.warn "Creado carrier en send"
          linea.warn carrier.inspect
          if presupuesto
            llamada =  presupuesto.llamadas.create(
                :minutos        => 0,
                :costo          => 0,
                :contenido      => id,
                :carrier_id     => carrier.id,
                :fono           => presupuesto.usuario.fono
            )
          end
          #options = {:response_body=>"{\"messages\":[{\"id\":\"wamid.HBgLNTY5ODM1NTA4NTkVAgARGBIxOUJGRTYzN0Q3N0ZCRkYwOEEA\"}]}"}

#{:response_body=>"{\"messages\":[{\"id\":\"wamid.HBgLNTY5ODM1NTA4NTkVAgARGBIxOUJGRTYzN0Q3N0ZCRkYwOEEA\"}]}", :debug_info=>#<Ethon::Easy::DebugInfo:0x000055e4d4b6bb88 @messages=[]>}') )
          linea.info id
          fact     = ::Graph::Fact.new(body)
          return id
          return fact.messages.first.id
          # hell yeah
        elsif response.timed_out?
          # aw hell no
          linea.warn "Time out"
          intentos = intentos + 1
          linea.info "Intento #{intentos}"
          sleep(5)
          unless intentos < WabaCfg.max_intentos
            return false
          end
          request.run
        elsif response.code == 0
          # Could not get an http response, something's wrong.
          linea.warn "No se recibió una respuesta http"
          linea.warn response.code

          intentos = intentos + 1
          linea.info "Intento #{intentos}"
          sleep(5)
          unless intentos < WabaCfg.max_intentos
            return false
          end
          request.run

        else
          # Received a non-successful http response.
          linea.warn "Se recibió una respuesta http no exitosa"
          intentos = intentos + 1
          linea.info "Intento #{intentos}"
          sleep(5)
          unless intentos < WabaCfg.max_intentos
            return false
          end
          request.run
        end
      end
      request.run
    end
  end

  def procesa_error response, presupuesto=nil, fono=nil
    #Algunos errores de la API WABA DE LA NUBE, Api Cloud Waba
    linea.info "En procesar error" 
    linea.info "Response es:"
    linea.info response.inspect

    puts response.inspect

    case response.is_a? String
    when true    
     body = JSON.parse(response)
    when false
     body = response
    end
    fact     = ::Graph::Fact.new(body)
    linea.info fact.inspect
    if fact&.error&.code 
      code = fact.error.code
      subcode = fact.error.error_subcode.nil? ? fact.error.error_subcode : ''

      unless code == 200 and fact&.error.error_subcode  == 2494049
        if code > 199 and code <= 300
          code = -200
        end
      end
      
      texto_mensaje = "Waba- Error #{code}: Ppto: #{presupuesto&.id} #{WabaCfg.error_descripcion[WabaCfg.error_id.index(code)]} \
      | #{WabaCfg.error_recomendacion[WabaCfg.error_id.index(code)]} | #{subcode}."

      Instalador.all.each{ |instalador|
        mensaje = {
                   title:          'Aviso de Error',
		   body:           "Ppto: #{(presupuesto.nil? ? '' : presupuesto.id )} | fono: #{(fono.nil? ? '' : fono)} | #{texto_mensaje}",
                   tag:            "weba_error#{code}",
                   tipo:           'aviso_a_instalador',
		   receiver_id:    instalador.id,
		   presupuesto_id: (presupuesto.nil? ? 0 : presupuesto.id ) ,
                   icon:           '/img/ticket_man_wave.png',
                   image:          '/img/wide-landing-04.jpg',
                   badge:          '/img/ticket_man_wave.png'
                  }              
         push_to( instalador, mensaje )
         # enviar_email( mensaje, instalador)
       }       
    end
    return code
  end
end

