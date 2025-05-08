module Graph
  class Payload < Graph::Button

    attr_accessor :text
    include Linea

    def initialize( text )
      @text = text
    end

    #PAra que tomar funcione, los mayoristas son colaboradores
    def procesa( fono=nil, mensaje_id=nil, publico=nil )


   end


    #PAra que tomar funcione, los mayoristas son colaboradores
    def procesa( fono=nil, mensaje_id=nil, publico=nil )
      linea.info "Estoy en procesa de Graph::Payload"
    
      if mensaje
        if mensaje.context
          @contexto = mensaje.context
          ::Waba::Transaccion.new(:cliente).responder( @fono, mensaje.context.id, "hisaje")

          linea.info "id: #{@contexto&.id} "
          @fono    =   mensaje.from
          linea.info "fono: #{@fono}"
          if @fono
            reporte = ::Reporte.find_by(:fono => @fono)
            if reporte
              case @text
                when "Es mi número"
                  linea.warn "Encontré el reporte"
                  linea.info reporte.inspect
                  reporte.update(:confirmado => true)
                  mensaje = "Hemos confirmado su número telefónico."
                  linea.warn mensaje
                  ::Waba::Transaccion.new(:cliente).responder( @fono, @contexto.id, mensaje)
                  #urbo::StreamsChannel.broadcast_render_to([current_user, :payouts],
                  #                       target: 'toast-container',
                  #                       partial: 'shared/update_toast',
                  #                       locals: { flash: flash_details })

    redirect_to merchant_payouts_path(state: @state)
                  return
              end
            else
              linea.fatal "No encontré el reporte"
            end
          end
        end
      end

      case @text

      #--- Ofertar|Tomar|Recargar
      #--- opciones del mensaje say_ofertar 
      #-- se envía al colaborador para que
      #-- tome un presupuesto que ha sido
      #-- generado por un cliente
      when "Ofertar"
        ofertar
      when "Tomar"
        tomar
      when "Recarga Paypal"
        recarga_paypal
      when "Recargar"
        recargar
      when "Agotado"
        agotado
      when "Error de Formato"
        error_de_formato
      #----........................
      #El colaborador puede pedir ayuda
      #Si ha sleccionado ofertar en 
      #respuesta a un aviso de nuevo
      #presupuesto
      when "Ayuda"
        ayuda
      #--- El colaboraor puede responder
      #--- con Entiendo o No entiendo
      #--- cuando un aviso de que no
      #--- fue posible entregarle el presupuesto
      #Entiendo|No se entiende
      when "Entiendo"
        entiendo
      #---- Este es un mensaje comodí
      #---- Que se usa en lugar de aceptar
      #---- Para saber el nivel de 
      #---- compromiso del colaborador
      #--- o mantener una conversación
      #---- más natural
      when "No se entiende"
        no_se_entiende
      when "Vale"
        vale
      #----- Alternativas de respuesta del cliente
      #----- Cuando se le pide que cofirme su número
      #----- de teléfono
      #Es mi número|Número equivocado
      when "Es mi número"
        es_mi_numero
      when "Número equivocado"
        numero_equivocado
      #----------------------------------------
      #Estas son las opciones cuando se envía un presupuesto en pdf
      "Qué Bien!|No estoy conforme|No quiero recibir esto"
      when "Qué Bien!"
        que_bien
      when "No estoy conforme"
        no_estoy_conforme
      when "Disconforme"
        no_estoy_conforme
      when "No envíe nada porfa!"
        no_quiero_recibir_esto
      when "No quiero recibir esto"
        no_quiero_recibir_esto
      #--------------------------------------------
      #"Qué Bien!|No estoy conforme|No quiere recibir esto"
      when "Qué Bien!"
        que_bien
      when "No estoy conforme"
        no_estoy_conforme
      when "No quiere recibir esto"
        no_quiere_recibir_esto
      #---- Aparece con el envío de imagenes
      #"Reportar uso Inapropiado"
      when "Reportar uso Inapropiado"
        uso_inapropiado
      else
        avisar_al_jefe
      end
    end

    def error_de_formato
      linea.warn "Recibí un mensaje Error de Formato"
    end

    def agotado
      linea.warn "Recibí un mensaje Agotado"
      @presupuesto.orden.servicios.each do |servicio|
        servicio.update(:cantidad_disponible => 0)
      end
      mensaje = "Recibimos su repuesta: Agotado. Gracias"
      ::Waba::Transaccion.new(:cliente).responder( @fono, @contexto.id, mensaje)
    end

    
    def tomar
      linea.warn "Recibí un mensaje Tomar"
      if @colaborador and @presupuesto
          linea.info "Intentando que el colaborador tome el presupuesto"
          @presupuesto.update(:mandato_aceptado => true) #Solo provisoriamente
          caso_de_uso = ::Electrico::CrearSolicitud.new ::Electrico::PresupuestoRepositorio, self
            #:Api::V1::Electrico::PresupuestosController.new
          caso_de_uso.tomar @presupuesto, @colaborador

      end
    end

    def solicitud_fallidamente_tomada presupuesto, colaborador
      ::Waba::Transaccion.new(:colaborador).say_fail presupuesto, colaborador
    end

    def solicitud_exitosamente_tomada presupuesto, colaborador
       ::Waba::Transaccion.new(:colaborador).say_exito presupuesto, colaborador
    end


    def ayuda
      linea.warn "Recibí un mensaje Ayuda"
      if @gestor and @colaborador and @presupuesto
        begin
         linea.warn "Intentando enviar presupuesto al gestor"
         @presupuesto.send_to_gestor
       rescue StandardError => e
          linea.error e.messages
        end
      end
    end


    def recargar
      linea.warn "Recibí un mensaje Recargar"
      if @presupuesto 
        servicio    = ::Comercio::Servicio.creditos.first
        valid_payload = {'user'=>{'email' => @colaborador.email}}
        auth_token   = JsonWebToken.encode(:reader => valid_payload )
        @presupuesto.send(:remember_token)
        url_de_pago="Clique en esta dirección para recargar: #{C.backend_url}/api/v1/electrico/presupuestos/#{@presupuesto.remember_token}/recargar/?auth_token=#{auth_token}"
        ::Waba::Transaccion.new(:colaborador).enviar_url( @fono, url_de_pago )
      end
    end


    def recarga_paypal
      linea.warn "Recibí un mensaje Recarga Paypal"
      if @presupuesto
        servicio    = ::Comercio::Servicio.creditos.first
        valid_payload = {'user'=>{'email' => @colaborador.email}}
        auth_token   = JsonWebToken.encode(:reader => valid_payload )
        @presupuesto.send(:remember_token)
        url_de_pago="Clique en esta dirección para recargar: #{C.backend_url}/api/v1/electrico/presupuestos/#{@presupuesto.remember_token}/recarga_paypal/?auth_token=#{auth_token}"
        ::Waba::Transaccion.new(:colaborador).enviar_url( @fono, url_de_pago )
      end
    end


    #usa Electrico::Carrier
    def recargar_antiguo
      linea.warn "Recibí un mensaje Recargar"
      linea.warn "Contexto es #{contexto.id}"
      carrier     = ::Electrico::Carrier.find_by(:nombre => contexto&.id)
      linea.warn "No fue encontrado carrier para contexto"
      linea.info contexto&.id

      if carrier and carrier&.nombre
        linea.warn carrier.nombre
        presupuesto = ::Electrico::Presupuesto.find( carrier.tarifa )
        linea.warn "presupuesto: "
        linea.warn presupuesto.descripcion 
        servicio    = ::Comercio::Servicio.creditos.first
        linea.warn "Servicio"
        linea.warn servicio.inspect
        colaborador = presupuesto.colaborador
        fono = mensaje.from
        colaborador = Colaborador.find_by(:fono => fono)

        valid_payload = {'user'=>{'email' => colaborador.email}}
        auth_token   = JsonWebToken.encode(:reader => valid_payload )

        presupuesto.send(:remember_token)
        url_de_pago="Clique en esta dirección para recargar: #{C.backend_url}/api/v1/electrico/presupuestos/#{presupuesto.remember_token}/recargar/?auth_token=#{auth_token}"
        ::Waba::Transaccion.new(:colaborador).enviar_url( fono, url_de_pago )
      end
    end

    def ofertar
      if @colaborador and @presupuesto and @colaborador.get_creditos_disponibles > 1
        linea.info "Enviando oferta al usuario del presupuesto #{@presupuesto.id}"
        @presupuesto.update(
                           :users_id    => @colaborador.id,
                           :bloqueado   => true,
                           :vigente     => false)
        #envia el presupuesto en pdf si es que existe
        #hay que bloquear el presupuesto antes y desbloquearlo despues, cuando el cliente haya pagado
        #se entregrará el presupuesto a la mejor oferta. #de momento, todas ls ofertas son iguales, 
        #Se entregrará el preupusesto al primero en haber ofertado
        
        begin
          @presupuesto.pdf
        rescue StandardError => e
          linea.error e.messages
        end

        #Envia el link de pago y las condiciones de pago
        resultado =  @presupuesto.ofertar

        visita = ::Comercio::Servicio.find_by(:gtin => 'gtin_visita')

        if resultado
          if visita
            ::Waba::Transaccion.new(:colaborador).say_mensaje_de_exito @presupuesto, @colaborador, \
            "Se ha enviado éxitosamente su oferta por $ #{visita.precio}. Si el cliente paga en la plataforma y luego de unos días, el monto afectado por impuestos y costos de procesamiento se transferirá a su cuenta bancaria."
          end
          #Enviando un botón de ayuda para que el colaborador solicite ayuda
        end


        #El cliente deberá pagar en Transbank
        #Recibirá un voucher 
        #Luego hay que asignarle el presupuesto al colaborador cuyo fono sea el que esté en la llamada
        #Pero ese flujo no lo puedo ver desde aquí, sino que continuará desde el punto de webpay 
        #donde es recibido en el servicio de compra unitaria webpay credito o algo así.
        #En una etapa siguiente habrá que espera el link de cliente tipo khipu y hacer lo mismo
        #Falta crear el presupuesto
        #caso_de_uso = ::Electrico::CrearSolicitud.new ::Electrico::PresupuestoRepositorio, self
        #caso_de_uso.tomar presupuesto, colaborador
      else
        if @colaborador.get_creditos_disponibles < 2
         ::Waba::Transaccion.new(:colaborador).responder( @colaborador.fono,  @contexto.id, "No se ha podido ofertar porque Su saldo es muy bajo. Necesita dos créditos o más para ofertar" )
        end
      end
    end

    def entiendo
      mensaje = "Recibimos su respuesta: Entiendo. Gracias"
      ::Waba::Transaccion.new(:cliente).responder( @fono, @contexto.id, mensaje)

      linea.warn "Recibí un mensaje Entiendo"
      if @colaborador.present? and @users_id == @colaborador.id
        linea.warn "Es un colaborador respondiende a un aviso de exito al enviar oferta"
        linea.warn "Itentaremos enviarle un botón de ayuda"
        linea.warn "Al presionar el botón de ayuda, un gestor podrá ayudarlo"
        ::Waba::Transaccion.new(:colaborador).say_ayuda( @presupuesto, @colaborador)
      end
    end


    def no_se_entiende
      mensaje = "Recibimos su repuesta: No Se Entiende. Gracias"
      ::Waba::Transaccion.new(:cliente).responder( @fono, @contexto.id, mensaje)
    end


    def vale
      linea.warn "Recibí un mensaje Vale"
      linea.warn "Fue originado por un gestor que ha presionado Vale en respuesta a una solicitud de ayuda"
      linea.warn "Intentaremos enviarle los datos del presupuesto en los que el oferente le ha solicitado ayuda"
      linea.warn "El oferente se debiese estar en el campo presupuesto.users_id"
      linea.warn "Intentando enviar los datos del presupuesto al gestor"
      linea.warn "presupuesto es"

      if @presupuesto and @presupuesto.valid?
        linea.warn @presupuesto.inspect
        ::Waba::Transaccion.new(:colaborador).enviar_presupuesto( @gestor, @presupuesto) 
        oferente = Colaborador.find_by(:id => @presupuesto.users_id )
        linea.warn "Oferente es #{oferente.name}" if oferente.present?
      else
        linea.error "No se encontró presupuesto" unless @presupuesto
        linea.error "El presupuesto no era válido" unless @presupuesto.valid?
      end
    end

    #Se confirmará al usuario que presione Es mi número
    def es_mi_numero
      linea.warn "Recibí un mensaje Es mi número"
     
      mensaje = "Recibimos su respuesta: Es mi número. Gracias"
      ::Waba::Transaccion.new(:cliente).responder( @fono, @contexto.id, mensaje)
    end

    def numero_equivocado
      mensaje = "Recibimos su respuesta: Número equivocado. Gracias"
      ::Waba::Transaccion.new(:cliente).responder( @fono, @contexto.id, mensaje)
    end

    def que_bien
      mensaje = "Recibimos su respuesta: Qué Bien. Gracias"
      ::Waba::Transaccion.new(:cliente).responder( @fono, @contexto.id, mensaje)
    end

    def no_estoy_conforme
      mensaje = "Recibimos su respuesta: No Estoy Conforme. Gracias, lo tendremos en cuenta."
      ::Waba::Transaccion.new(:cliente).responder( @fono, @contexto.id, mensaje)
    end

    def no_quiero_recibir_esto
      mensaje = "Recibimos su respuesta: No quiere recibir esto. Lo sentimos, pero era necesario."
      ::Waba::Transaccion.new(:cliente).responder( @fono, @contexto.id, mensaje)
    end

    def uso_inapropiado
      mensaje = "Recibimos su respuesta: Reportar uso Inapropiado. Lo tendremos en cuenta."
      ::Waba::Transaccion.new(:colaborador).responder( @fono, @contexto.id, mensaje)
    end


    def avisar_al_jefe
      mensaje = "Recibimos un payload que no pudimos procesar: #{@text}"
      ::Waba::Transaccion.new(:admin).responder( C.fono_jefe, @contexto.id, mensaje)
    end

    def self.json_create(o)
      attrs = JSON.parse(o['data'], :quirks_mode => true )
      n = ::Graph::Payload.new(
        attrs
      )
    end

    def to_json(*a)
      data = { 'text'    => @text   }
      { 'json_class' => self.class.name,
        'data' => data.to_json(*a) }
    end

    def monito
      " (payload (text #{@text.parameterize}))"
    end

    def put
      " (payload (text #{@text}))"     
    end

  end
end
