#La responsabilidad de esta clase es procesar los mensajes waba que son remitidos a un webhook 
#Esto parte en el controlador api/v1/electrico/presupuestos/webhook
#
class Waba::Webhook

  attr_accessor :mensajes
  extend Linea
  include CrearUsuario


  def initialize params

    linea.info "En initialize de Waba::Webhook"
    linea.info "Debe hacer lo que hace la accioń webhook en api/v1/electrico/presupuestos"

   #performed? recordar que se puede usar para detectar si ya no se haya respondido en otro lado
    unless AGENDA<<params
      return
    end
    linea.info params.inspect
    fact = Graph::Fact.new(params, nil, nil)
    linea.info fact.inspect
    fact&.send(:monito, ::Graph::Redisfile.new)

    #Los mensajes llegan en diferents posiciones de la graph.api
    begin
      @mensajes = fact.object.entry.first.changes.first.value.messages
    rescue StandardError => e
      @mensajes = fact.messages
    end

    linea.info "antes de verificar mensajes"
    if @mensajes&.any?
      linea.info "Tiene mensajes"
      @mensajes.each do |mensaje| 
        contexto = mensaje&.context
        if mensaje.respond_to?(:button) and mensaje&.button and contexto&.respond_to?(:id) and contexto&.respond_to?(:from)
          #es un mensaje de botones, típico de usuarios que responden a avisos originados desde la plataforma
          #Por ejemplo cuando se pide, este es tu numero y se dejan dos botones, "sí es mi número", "no es mi número"
          procesa_mensaje mensaje, contexto
        else
          detecta_publico fact
        end
      end
    elsif fact.respond_to?(:solicitud) and fact.solicitud
      #son solicitudes desde la plataforma para que waba envíe avisos a los clientes y colaboradores
      #no se procesan
      procesa_solicitud fact.solicitud
    else
      #son wabas que no caen en ninguna de las categorías que podemos identificar y simplmente se reenvían al número personal del instalador.
      linea.info "Waba que no cae en ninguna categoría, se hará echo hacia el telefóno del Gestor Principal"
      linea.info fact.inspect
      fact.eco
    end

  #  if fact.object.entry.first.changes.first.value.messages.any?
  #    detecta_publico( fact )
  #  else
      #no atiendo mensajes de status ni de error
   # end
  end

  def atender_publico_colaborador( fact, mensaje, fono )

    case mensaje.type
    when "unknown"
      return
    when "sticker"
      return
    when "reaction"
      return
    when "order"
      ::Waba::Orden.new(fact).procesa
      return
    when "location"
      ::Waba::Location.new(fact).procesa
      return
    when "text"
      ::Waba::Conversacion.new(fact, :colaborador).procesa
      return
    when "interactive"
      fact.procesa( fono, mensaje.id, :colaborador)
      return
    when "button"
      mensaje.button.procesa( self )
      return
    when "video"
      ::Waba::Video.new(fact).procesa
      return
    when "image"
      ::Waba::Image.new(fact).procesa
      return
    when "status"
      fact.procesa
      return
    when "request_welcome"
      envia_bienvenida fact, :colaborador
    end

  end


  def detecta_publico( fact )
    linea.info "En detecta_publico"
    #uso dos números waba, uno para los colaboradores y otro para los clietnes
    metadata         = fact.object.entry.first.changes.first.value.metadata
    origin_phone_id  = metadata.display_phone_number
    mensajes         = fact.object.entry.first.changes.first.value.messages
    mensaje          = mensajes.first
    fono             = mensaje.from
    contexto         = mensaje&.context

    linea.info "Fono de origen"
    linea.warn origin_phone_id

    linea.info "Fono de contacto para colaboradores"
    linea.info WabaCfg.display_phone_number_colaboradores

    linea.info "Fono de contacto para clientes"
    linea.warn WabaCfg.display_phone_number_clientes

    case origin_phone_id.to_i

    #Cuando se usa el fono que está disponible para atender a los colaboradores
      #Solo enviar una tarjeta de contacto
    when WabaCfg.display_phone_number_colaboradores
      linea.info "Público es colaboradores"
      case mensaje.type
      when "request_welcome"
        envia_bienvenida fact, :colaborador
      end
      atender_publico_colaborador( fact, mensaje, fono )

    when WabaCfg.display_phone_number_clientes
      linea.info "Público es clientes"
      #::Waba::Transaccion.new(:cliente).enviar_contacto_alectrico(C.fono_test)
      case mensaje.type
      when "unknown"
        return
      when "sticker"
        return
      when "reaction"
        #end
        return
      when "order"
        #destinado a ser enviado por cliente potencial
        #por tanto el publico es cliente
        ::Waba::Orden.new(fact).procesa
        return
      when "location"
        ::Waba::Location.new(fact).procesa
        return
       when "text"
         ::Waba::Conversacion.new(fact).procesa
         #respond_to debe estar despues de procesa
         #porque algunso procesamientos hace redireccion
         #a otros métodos de controladores
         #e incluso en otros controladores
         #Eso justifica usar performed?, pero eso ahora se ve en el controlador
         return
      when "interactive"
         fact.procesa( fono, mensaje.id,:cliente)
         return
      when "button"
        linea.info "Button detectado"
        mensaje.button.procesa( fono, mensaje.id, :cliente)
        return
      when "video"
         ::Waba::Video.new(fact).procesa
         return
      when "image"
         ::Waba::Image.new(fact).procesa
         return
      when "request_welcome"
        envia_bienvenida fact, :cliente
      end
    end
  end

  def envia_bienvenida( fact, publico)
    ::Waba::Transaccion.new( publico ).enviar_mensaje(fono, "¡Bienvenido a alectrico ®!")
    nombre = fact.object.entry.first.changes.first.value.contacts.first.profile.name
    begin
      mensajes = fact.object.entry.first.changes.first.value.messages
    rescue StandardError => e
      mensajes = fact.messages
    end

    if mensajes&.any?
      mensaje  = mensajes.first
      fono     = mensaje.from
      contexto = mensaje&.context
      usuario = crear_usuario( fono, nombre, "#{fono}_cliente@alectrico.cl" )

      presupuesto = ::Electrico::Presupuesto
           .no_pagado
           .efimero
           .no_realizado
           .vigente
           .find_by(:fono => fono )

      unless presupuesto
        mensaje = "#{nombre}, parece que es su primera visita a alectrico®, crearemos una ficha de presupuesto."
        ::Waba::Transaccion.new(publico).responder( fono, mensaje.id, mensaje)

        presupuesto = ::Electrico::Presupuesto.create(
          {
            :descripcion   => "",
            :instalador_id => ::Instalador.first.id,
            :efimero       => true,
            :fono          => fono,
          }
        )
      end
      ::Waba::Transaccion.new( publico ).say_reservar(fono, presupuesto)
    end
  end

  #Intenta lograr que un colaborador tome un presupuesto
  def realizar_tomar mensaje, contexto
    colaborador = ::Colaborador.find_by(:fono => mensaje.from )
    llamada = ::Electrico::Llamada.find_by(:contenido => contexto&.id)
    fono    = mensaje&.from

    if llamada&.valid? and fono

      colaborador = ::Colaborador.find_by(:fono => fono )
      presupuesto = llamada.presupuesto

      if colaborador and presupuesto
        presupuesto.update(:mandato_aceptado => true) #Solo provisoriamente
        caso_de_uso = ::Electrico::CrearSolicitud.new ::Electrico::PresupuestoRepositorio, \
          ::Api::V1::Electrico::PresupuestosController.new
        caso_de_uso.tomar presupuesto, colaborador
      end
    end
  end

  def envia_presupuesto_en_formato_pdf presupuesto
    presupuesto.pdf
  end

  def envia_requerimiento_de_pago presupuesto
    presupuesto.bienvenido
  end

  def envia_waba_de_exito presupuesto, colaborador
    ::Waba::Transaccion.new(:colaborador).say_mensaje_de_exito presupuesto, colaborador,\
    "Se ha enviado éxitosamente su oferta."
    ::Waba::Transaccion.new(:colaborador).say_ayuda presupuesto, colaborador
  end

  #--------------- Atencion a botones
  #Debe llamarse cuando se reciba un botón Entiendo desde el fono del gestor
  #en respuesta a un mensaje plantilla cualquiera que tenga el botón Entiendo
  def solicitar_gestor mensaje, contexto
    linea.info "Recibí un mensaje Ofertar"
    llamada = ::Electrico::Llamada.find_by(:contenido => contexto&.id)
    linea.info "id: #{contexto&.id} "
    fono    = mensaje&.from
    linea.info "fono: #{fono}"

    if llamada&.valid? and fono

      colaborador = ::Colaborador.find_by(:fono => fono )
      linea.info "Colaborador: #{colaborador.name}"
      presupuesto = llamada.presupuesto

      linea.info "Presupuesto: #{presupuesto.id}"
      linea.info presupuesto.descripcion

      gestor      = ::Colaborador.find_by(:fono => C.fono_gestor )

      if colaborador and presupuesto and gestor
        linea.info "Solicitando ayuda en el presupuesto #{presupuesto.id} a #{gestor.name}"
        presupuesto.update( :con_backup  => true,
                            :users_id   => gestor.id )

        #envia el presupuesto en pdf si es que existe
        #hay que bloquear el presupuesto antes y desbloquearlo despues, cuando el cliente haya pagado
        #se entregrará el presupuesto a la mejor oferta. #de momento, todas ls ofertas son iguales, 
        #Se entregrará el preupusesto al primero en haber ofertado
        #Envía los datos de contacto y de detalle al gestor para que contacte al cliente, para convencerlo de que finalmente
        #Este siga el proceso de toma de oferta, proceso que ha originado un bloqueo en presupuesto
        #El que solo será desbloqueado cuando el cliente pague con el link de pago
        #En ese momento se descontará una batería del colaborador y será acreditadaagregada como servicio a una orden del
        #gestor
        #Esto en paralelo con la generación de rendicoines
        #Y la realización de una transferencia vía Khipu
        ::Waba::Transaccion.new(:cliente).enviar_presupuesto(gestor, presupuesto)
     end
    end
  end

  def enviar_presupuesto mensaje, contexto
    linea.info "Enviendo presupuesto, detalles al gestor"
    llamada = ::Electrico::Llamada.find_by(:contenido => contexto&.id)
    linea.info "id: #{contexto&.id} "
    fono    = mensaje&.from
    linea.info "fono: #{fono}"

    if llamada&.valid? and fono

      colaborador = ::Colaborador.find_by(:fono => fono )
      linea.info "Colaborador: #{colaborador.name}"
      presupuesto = llamada.presupuesto

      linea.info "Presupuesto: #{presupuesto.id}"
      linea.info presupuesto.descripcion

      if colaborador and presupuesto
        linea.info "Enviando oferta al usuario del presupuesto #{presupuesto.id}"
      end
    end
  end

  def realizar_ofertar mensaje, contexto
    linea.info "Recibí un mensaje Ofertar"
    llamada = ::Electrico::Llamada.find_by(:contenido => contexto&.id)
    linea.info "id: #{contexto&.id} "
    fono    = mensaje&.from
    linea.info "fono: #{fono}"

    if llamada&.valid? and fono

      colaborador = ::Colaborador.find_by(:fono => fono )
      linea.info "Colaborador: #{colaborador.name}"
      presupuesto = llamada.presupuesto

      linea.info "Presupuesto: #{presupuesto.id}"
      linea.info presupuesto.descripcion

      if colaborador and presupuesto
        linea.info "Enviando oferta al usuario del presupuesto #{presupuesto.id}"


        presupuesto.update(
                           :users_id    => colaborador.id,
                           :bloqueado   => true,
                           :vigente     => false)
        #envia el presupuesto en pdf si es que existe
        #hay que bloquear el presupuesto antes y desbloquearlo despues, cuando el cliente haya pagado
        #se entregrará el presupuesto a la mejor oferta. #de momento, todas ls ofertas son iguales, 
        #Se entregrará el preupusesto al primero en haber ofertado

        begin
          envia_presupuesto_en_formato_pdf presupuesto
        rescue StandardError => e
          linea.error e.messages
        end

        #Envia el link de pagoy las condiciones de pago
        resultado = envia_requerimiento_de_pago presupuesto

        envia_waba_de_exito presupuesto, colaborador if resultado
        #El cliente deberá pagar en Trasbank
        #Recibirá un voucher 
        #Luego hay que asignarle el presupuesto al colaborador cuyo fono sea el que esté en la llamada
        #Pero ese flujo no lo puedo ver desde aquí, sino que continuará desde el punto de webpay 
        #donde es recibido en el servicio de compra unitaria webpay credito o algo así.
        #En una etapa siguiente habrá que espera el link de cliente tipo khipu y hacer lo mismo
        #Falta crear el presupuesto
        #caso_de_uso = ::Electrico::CrearSolicitud.new ::Electrico::PresupuestoRepositorio, self
        #caso_de_uso.tomar presupuesto, colaborador
     end
    end
  end


  def procesa_mensaje mensaje, contexto
    linea.info "Recibí un mensaje <Button>"

    linea.info mensaje.inspect

    if mensaje.button.respond_to?(:payload)
      mensaje.button.payload.procesa
    end
    #case mensaje.button.payload.text
    #when "Recargar"
    #  linea.info "Es un mensaje <Recargar>"
    #  mensaje.button.payload.procesa
    #when "Tomar"
    #  linea.info "Es un mensaje <Tomar>"
     # realizar_tomar mensaje, contexto
    #when "Ofertar"
    #  linea.info "ES un mensaje <Ofertar>"
    #  realizar_ofertar mensaje, contexto
    #when "Ayuda"
    #  linea.info "ES un mensaje <Ayuda>"
   #   solicitar_gestor mensaje, contexto
    #when "Entiendo"
    #  linea.info "Es un mensaje <Entiendo>"
    #  if mensaje.from == C.fono_gestor
    #    solicitar_gestor mensaje, contexto
    #  end
    #when "No Entiendo"
    #  linea.info "Es un mensaje <No Entiendo>"
    #else
    #  linea.warn "Es un mensaje que no puedo usar"
    #end
  end

  def procesa_solicitud solicitud
    linea.info "Recibí un mensaje <Solicitud>"
    linea.info "No se deben procesar en webhook"
    linea.info "Se retornará true si están correctos"
    if solicitud&.type == "template"
      template = solicitud.template
      linea.info "La solicitud es un template"
      #los templates están en el servidor de facebook
      #y uno los invoca con una sentencia http
      #por ejemplo para enviar un saludo
      case template.name
      when "nuevo_servicio"
        linea.info "El template es 'nuevo servicio', hay que dejarlo ir hacia el WABA del colaborador"
        linea.info "Pero verificaremos si el butón permite tomar presupuestos"

        componentes = template.components
        if componentes.last.type == "button"
          boton = componentes.last
          if boton.sub_type == "url" and \
             boton.parameters.first.text ==\
               "/electrico/presupuestos/#{presupuesto_id}/aceptar_contrato_y_tomar_presupuesto"
          end
        end
        return true
      when "ayuda"
        linea.info "El template es ayuda"
        return true
      when "tomar"
        linea.info "El template es tomar"
        return true
      when "ofertar"
         linea.info "El template es ofertar"
         return true
      when "recargar"
        linea.info "El template es recargar"
        return false
      end
      return false
    end
  end
end
