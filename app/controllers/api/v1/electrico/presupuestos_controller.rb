module Api
  module V1
    module Electrico

      class ComandoSinEmail < Struct.new( :nombre, :fono, :descripcion, :direccion, :comuna)
        attr_reader :nombre
        attr_reader :fono
        attr_reader :descripcion
        attr_reader :direccion
        attr_accessor :comuna
        attr_accessor :email

        def initialize( 
                        nuevo_nombre,
                        nuevo_fono,
                        nueva_descripcion,
                        nueva_direccion )

          @nombre      = nuevo_nombre
          @fono        = nuevo_fono
          @descripcion = nueva_descripcion
          @direccion   = nueva_direccion
        end


	def to_json
	  to_hash.to_json
	end

        def to_hash
          {
            'nombre'       => nombre,
            'fono'         => fono,
            'descripcion'  => descripcion,
            'direccion'    => direccion,
            'comuna'       => comuna,
            'email'        => email
          }
        end
      end


      class Comando < Struct.new(:email, :nombre, :fono, :descripcion, :direccion, :comuna)

        attr_reader :nombre
        attr_reader :fono
        attr_reader :descripcion
        attr_reader :direccion
        attr_accessor :comuna
        attr_reader :email

	def initialize( nuevo_email,
                        nuevo_nombre,
	                nuevo_fono,
	       	        nueva_descripcion,
	       	        nueva_direccion )

	  @nombre      = nuevo_nombre
	  @fono        = nuevo_fono
	  @descripcion = nueva_descripcion
	  @direccion   = nueva_direccion
	  @email       = nuevo_email
	end

	def to_json
	  to_hash.to_json
	end
   
        def to_hash
	  {
	    'nombre'       => nombre,
            'fono'         => fono,
            'descripcion'  => descripcion,
            'direccion'    => direccion,
            'comuna'       => comuna,
	    'email'        => email
	  }.to_json
        end
      end

#(.*\@.*\..{2})(.*)(\d{9})(.*)providencia(.*)
      #funciona así
      #hhhh@cjj.clana987654321corto en la cocinaprovidencialos apostoles 2546
      #se obtiene
      #email= hhh@cjj.cl 
      #nombre = ana
      #fono987654321
      #descripicion=corto en la cocina
      #comuna=providencia
      #direccion=los apostoles 2546
      #
      COMANDO_TEMUCO=/^(\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z )(.*)(\d{9})(.*)temuco(.*)/i
      COMANDO_TEMUCO_SIN_EMAIL=/^(.*)(\d{9})(.*)temuco(.*)/i

      COMANDO_PROVIDENCIA=/^(.*\@.*\..{2})(.*)(\d{9})(.*)providencia(.*)/
      COMANDO_PROVIDENCIA_SIN_EMAIL=/^(.*)(\d{9})(.*)providencia(.*)/

      COMANDO_SANTIAGO=/^(.*\@.*\..{2})(.*)(\d{9})(.*)santiago(.*)/
      COMANDO_SANTIAGO_SIN_EMAIL=/^(.*)(\d{9})(.*)santiago(.*)/

      COMANDO_ÑUÑOA=/^(.*\@.*\..{2})(.*)(\d{9})(.*)ñuñoa(.*)/
      COMANDO_ÑUÑOA_SIN_EMAIL=/^(.*)(\d{9})(.*)ñuñoa(.*)/


      class PresupuestosController < Api::V1::ElectricoController
        include Linea
        include Biblioteca::Mensajeria
        include CrearUsuario

        before_action :authenticate_request, :except => [:create_from_landing_page, :refund, :webhook, :download_unilineal_pdf, :return_webpay_aceptar_oferta, :return_webpay_recargar]

        #No puedo controlar cors para los download porque facebook no me deja manipular los headers
	#Tambíén porque no puedo obtner el nombre de dns del host remoto dado que corresponde a un proxy
        #de cloudlflre
        #No puedo dejar de usar ese proxy porque se requiere una conexion https que cloudflare ofrece
        #No quiero gastar en firmas para ofrecer dns
        #Sí puedo tomar el token y verificar que corresponda al dueño del presupuesto que se está accesando.

        before_action :commited_tbk_params, only: [:return_webpay_pagar_visita]

        before_action :cors,:except => [:create_from_landing_page, :tomar,  :download_factura, :download_boleta, :download_levantamiento_pdf, :download_pdf, :download_unilineal_pdf,:download_circuitos_pdf,:pagar, :pagar_oferta, :pagar_visita, :recargar, :webhook, :return_webpay_aceptar_oferta, :return_webpay_recargar]

        before_action :cors_no_amp, :only => [:create_from_landing_page]

	before_action :cache_config, :except => [:tomar, :pagar, :pagar_oferta, :pagar_visita, :webhook]

        before_action :no_cache, :only => [:create_from_landing_page, :pagar, :pagar_oferta, :pagar_visita, :recargar, :webhook, :return_webpay_aceptar_oferta, :return_webpay_recargar]

        def create_from_landing_page
          linea.info "En create_from_landing_page"
          linea.info landing_params

          data = landing_params["data"]

          nombre      = data["0"][1]
          fono        = data["1"][1]
          email       = data["2"][1]
          msg         = data["3"][1]
          comuna      = data["4"][1]
          direccion   = data["5"][1]
          landing_page= data["6"][1]

          usuario = crear_usuario( fono, nombre, email )
          presupuesto =  ::Electrico::Presupuesto.create( {:usuario => usuario, 
                                                           :efimero => true,
                                                           :direccion => direccion, 
                                                           :fono => fono, 
                                                           :comuna => comuna, 
                                                           :descripcion => msg})

          mensaje = "Hola Jefe, *#{nombre}* le ha envíado el siguiente mensaje desde la landing page #{landing_page}.
          _#{msg}_
          ---
          #{fono} #{email}
          #{direccion}#{comuna}     
          ---
          Nota: puede llamar */comunicar* #{presupuesto.id} para avisarle a los colaboradores-"

          #presupuesto.comunicar
          #::Waba::Transaccion.new(:colaborador).enviar_mensaje(C.fono_jefe, mensaje)
            #enviar_mensaje solo sirve is el usuario ya se ha comunicado con este número dentro 
            #de 24 horas
          #say_reservar es de marketing es más caro, pero no necesita que el usuario se
            #haya comunicado antes
          ::Waba::Transaccion.new(:cliente).say_reservar(fono, presupuesto)

          respond_to do |format|
             format.json { render json: { :status => :ok  } }
          end

        end

        def verifica params
          linea.info "En verifica"
	  linea.info waba_params.inspect
          es_challenge = false
          modo      = waba_params['hub.mode']
          challenge = waba_params['hub.challenge']
          token     = waba_params['hub.verify_token']
          linea.info "Token a verificar es:"
          linea.info token

          linea.info "Token en Waba"
          linea.info WabaCfg.token_de_verificacion


          if modo == 'subscribe' and token == WabaCfg.token_de_verificacion.to_s
            linea.info "Es challenge"
            linea.info "Se devolverá"
            linea.info challenge
            es_challenge = true
            render plain:  challenge , status: :ok  
          else
            linea.info "No es challenge"
            render json: { :Error => "El acceso no está permitido!" }, status: :not_found  
          end
        end


        #este webhook no revisa qué waba lo ha invocado
        #y en waba_transaccion se usará el waba de clientes
        #Esto es transitorio
        #Estructura general de los mensajes recibidos en webhook
        #https://developers.facebook.com/docs/whatsapp/cloud-api/webhooks/components
 #      {
 #"object": "whatsapp_business_account",
 #"entry": [{
 #  "id": "WHATSAPP-BUSINESS-ACCOUNT-ID",
 #  "changes": [{
 #    "value": {
 #       "messaging_product": "whatsapp",
 #       "metadata": {
 #         "display_phone_number": "PHONE-NUMBER",
 #         "phone_number_id": "PHONE-NUMBER-ID"
 #       },
      # Additional arrays and objects
 #       "contacts": [{...}]
 #       "errors": [{...}]
 #       "messages": [{...}]
 #       "statuses": [{...}]
 #    },
 #    "field": "messages"
 #  }]
 #}]
#}
        #https://developers.facebook.com/docs/whatsapp/cloud-api/guides/set-up-webhooks
        #{
 #"object": "whatsapp_business_account",
 #"entry": [{
 #    "id": "WHATSAPP_BUSINESS_ACCOUNT_ID",
#     "changes": [{
#         "value": {
#             "messaging_product": "whatsapp",
#             "metadata": {
#                 "display_phone_number": "PHONE_NUMBER",
#                 "phone_number_id": "PHONE_NUMBER_ID"
#             },
              # specific Webhooks payload
#         },
#         "field": "messages"
#       }]
#   }]
#
        #}
        #endpoint para flows con contenido dinámico
        def flows
          linea.warn "En flow"
          linea.info "waba_params es:"
          linea.info waba_params.inspect
          ::Waba::Flow.new( presupuesto_params )
          unless performed?
            respond_to do |format|
              format.json { render json: { :status => :ok  } }
            end
          end 
        end

        def webhook
          linea.warn "En webhook"
	  linea.info "waba_params es:"
	  linea.info waba_params.inspect
          if presupuesto_params['hub.mode'] == 'subscribe'
            verifica presupuesto_params
            return
          else
            ::Waba::Webhook.new( presupuesto_params )
            #Tests if render or redirect has already happened.
            unless performed?
              respond_to do |format|
                format.json { render json: { :status => :ok  } }
              end
            end
          end 
        end

        def solicitar_gestor mensaje, contexto
          linea.info "Recibí un solicitar_gestor"
          llamada = ::Electrico::Llamada.find_by(:contenido => contexto&.id)
          linea.info "id: #{contexto&.id} "
          fono    = mensaje&.from.last(13)
          linea.info "fono: #{fono}"

          if llamada&.valid? and fono

            colaborador = ::Colaborador.find_by(:fono => fono.last(13) )
            linea.info "Colaborador: #{colaborador.name}"
            presupuesto = llamada.presupuesto

            linea.info "Presupuesto: #{presupuesto.id}"
            linea.info presupuesto.descripcion

            gestor      = ::Colaborador.find_by(:fono => C.fono_gestor )

            if colaborador and presupuesto and gestor
              linea.info "Solicitando ayuda en el presupuesto #{presupuesto.id} a #{gestor.name}"
              presupuesto.update( :con_backup  => true,
                                  :users_id  => gestor.id )
              ::Waba::Transaccion.new(:colaborador).enviar_presupuesto(gestor, presupuesto)
              #Esto continuar cuando el usuario intente pagar siguiendo el link de pago
              #
              #ea def return_webpay_aceptar_oferta
           end
          end
        end

        def return_webpay_aceptar_oferta
          linea.info "En return_webpay_aceptar_oferta en Api/V1/electrico/presupuestos"
          linea.info "Los parámetros son. #{presupuesto_params.inspect}"
          compra = ::Comercio::Compra::Unitaria::Webpay::Nominativo::Manual.new( ::Comercio::OrdenRepositorio, self, nil, nil, nil, nil )
          compra.procesa_return presupuesto_params
          #esto sigue abajo en los defs de notificacion_webpay_exitosa o fallida
        end

        def return_webpay_recargar
          puts "En return_webpay_recargar en Api/V1/electrico/presupuestos"
          puts "Los parámetros son. #{presupuesto_params.inspect}"
          compra = ::Comercio::Compra::Unitaria::Webpay::Recarga.new( ::Comercio::OrdenRepositorio, self, nil, nil, nil, nil )
          compra.procesa_return presupuesto_params
          #esto sigue abajo en los defs de notificacion_webpay_exitosa o fallida
        end

        def notificacion_recarga_exitosa iduo
          puts "Estoy en notificacion_recarga_exitosa iduo es: #{iduo}"

          @orden = ::Comercio::Orden.find_by(:iduo => iduo)

	  begin

            link = download_voucher_pdf_comercio_orden_url(
              :id => @orden.id,
              :format => :webpay )

	     puts "link para descargar pdf es:"
	     puts link

	     puts "Se llama a Waba para enviar documentos"
             ::Waba::Transaccion.new(:colaborador).enviar_documento(
               link,
               "voucher.pdf",
	       @orden.user.fono  )
            
	  rescue StandardError => e
            puts e.inspect
          end
          puts "No se pudo encontrar la orden" unless @orden.present?
          puts "Orden es #{@orden.inspect}" if @orden.present?
          respond_to do |format|
            format.html do
	      if @orden and @orden.status == 'AUTHORIZED'
		puts "planificando una respuesta positiva"
	        @result =  result_hash = {
		      :header => "¡Bien!",
		      :icon => "success",
		      :message => "Su recarga ha sido aprobada.",
		      :pasarela => "webpay"
		    }
	       else
	         @result =  result_hash = {
		      :header => "¡Bah!",
		      :icon => "fail",
		      :message => "Hubo un problema y su recarga no ha sido aprobada.",
		      :pasarela => "webpay"
		    }
	       end
	      puts "renderizando la respuesta en template comercio/ordenes/return_webpay"
	      puts "La orden tiene creditos" if  @orden.servicios.creditos.any?
	      puts "La orden no tiene créditos " unless @orden.servicios.creditos.any?
	      render  :template => '/comercio/ordenes/return_webpay', :action => :show, :id => @orden.try(:payment_id), :formats => [:html], :layout => 'layouts/braintree_sin_csrf'
	    end

	    format.json do
	      if @orden
	        render json: { "notificacion_recarga_exitosa: orden es" => @orden.inspect }
	      else
	        render json: { "notificacion_recarga_exitosa" => "intento fallido" }
	      end
            end
	  end
        end

          def notificacion_webpay_exitosa iduo
            puts "Estoy en notificacion_webpay_exitosa iduo es: #{iduo}"


            @orden = ::Comercio::Orden.find_by(:iduo => iduo)

            puts "No se pudo encontrar la orden" unless @orden.present?

            if @orden.present?

              #puts "Orden es #{@orden.inspect}"

              presupuesto = @orden.presupuesto 

	      if presupuesto
                puts "Presupuesto es #{presupuesto.inspect}" 
              end

	      puts "ids:"
	      puts presupuesto.users_id

              colaborador = ::Colaborador.find_by(:id => presupuesto.users_id)
	      if colaborador
                puts "colaborador que oferta es: "
	        colaborador.name
              end

              puts "Lista de Colaboradores"
	      ::Colaborador.all.each do |c|
		 puts c.name
		 puts c.fono
	      end 
	      puts "Fono Gestor"
	      puts C.fono_gestor
              gestor      = ::Colaborador.find_by({:fono => C.fono_gestor})

	      if gestor
	        puts "gestor que gestiona es: "
	        puts gestor.name
	      end

	      if colaborador and presupuesto and gestor 
	        puts "Están todos"
                puts "Colaborador: #{colaborador.name}"
                puts "Gestor:      #{gestor.name}"

                #elaborar el caso de uso para que se traspase un crédio desde una orden con crédito del 
                #colaborador.
                #si el colaborador no tiene batería, será desactivado, Cuando el colaborador compre batería será nuevamente
                #activado en forma automática
	        #el colaborador debe tener al menos dos créditos disponibles
	        #Uno se quemará y el otro es el pago para alectrico
                if colaborador.get_creditos_disponibles > 1
		  puts "El colaborador tiene al menos 2 créditos disponibles"
                  #Quemaré un crédito, que luego tengo que pagarlo al gestor
                  #Así es como el colaborador le paga al gestor por su servicio 
                  #de conseguir el pago del cliente
                  antes = colaborador.get_creditos_disponibles
		  orden = ::Electrico::CrearSolicitud.new.find_orden colaborador
		  puts orden.inspect
		  ::Electrico::CrearSolicitud.new.borrar_un_credito orden

                  despues = colaborador.get_creditos_disponibles

                  unless despues < antes
                    puts "No pude quemar un crédito del colaborador"
                  end

                  #Ahora fabrico un crédito para el gestor
		  #Intando fabricar un cŕedito para el gestor
		  #puts "Orden es #{orden.inspect}"
		  orden_params = orden.attributes
		  #puts "Los parametros de la orden son #{orden_params}"

		  caso_de_uso = ::Comercio::CreaOrden.new(::Comercio::Orden, nil)
		  resultado = caso_de_uso.crea( gestor, orden_params )
		  if resultado
     		    puts "Se creó la orden para el gestor"
		  end		
                  credito = ::Comercio::Servicio.creditos.first
                  orden.servicios << credito
                  orden.update(:pagado => true, :status => 'AUTHORIZED')

                  unless gestor.get_creditos_disponibles > 0 
                   puts "El gestor no pudo conseguir los créditos."
                  end
                  #esto provoca que el gestor tome la copia del presupuesto
                  caso_de_uso = ::Electrico::SolicitudCompartida.new \
                  ::Electrico::PresupuestoRepositorio, self
                  caso_de_uso.tomar presupuesto, gestor

                  puts "Intentando que el colaborador tome el presupuesto"
                  #esto provica que el colaborador tome el presupuesto
                  #puede fallar si el colaborador no tuviese batería
                  #Eso dejería sin tomar el presupuesto
                  #Habría que difundirlo, pero ahora estaría con pago anticipado, no está mal!
                  presupuesto.update(:bloqueado        => nil,
                                 :vigente          => true,
                                 :users_id         => nil, 
                                 :mandato_aceptado => true) 

                  caso_de_uso = ::Electrico::CrearSolicitud.new ::Electrico::PresupuestoRepositorio, self
                  caso_de_uso.tomar presupuesto, colaborador

		  begin
                    #::Waba::Transaccion.new(:colaborador).enviar_presupuesto( colaborador, presupuesto) if presupuesto.valid?
                    #::Waba::Transaccion.new(:colaborador).enviar_presupuesto( presupuesto.user, presupuesto) if presupuesto.user.any?

                    link = download_voucher_pdf_comercio_orden_url(
                      :id => @orden.id,
                      :format => :webpay )

                    puts "link para descargar pdf es:"
                    puts link

                    puts "Se llama a Waba para envair documentos"

                    ::Waba::Transaccion.new(:colaborador).enviar_documento(
                      link,
                      "voucher.pdf",
                      @orden.user.fono  )

                  rescue StandardError => e
                     puts e.inspect
                  end

                  puts "Camino de las rosas, todo bien"
                else
                  presupuesto.difundir unless presupuesto.colaborador.present?
                  puts "El colaborador no tiene suficientes créditos para tomar el presupuesto"
		  puts "El cliente recibirá un mensaje de éxito y el prespuesto estará pagado"
		  puts "Pero el presupuesto on tendrá colaborador"
		  puts "Por eso se vuelve a difundir pero ya estará pagado y no está bloqueado"
		  puts "De esa forma otro colaborador con créditos lo podrá tomar"
	        end #creditos_disponibles
              end #colaborador y presupuesto y gestor

              respond_to do |format|
                format.html do
                  if @orden and @orden.status == 'AUTHORIZED'
                    @result =  result_hash = {
                    :header => "¡Bien!",
                    :icon => "success",
                    :message => "Su compra ha sido aprobada.",
                    :pasarela => "webpay"
                    }
                  else
                    @result =  result_hash = {
                    :header => "¡Bah!",
                    :icon => "fail",
                    :message => "Hubo un problema y su compra no ha sido aprobada.",
                    :pasarela => "webpay"
                    }
                  end

                  render  :template => '/comercio/ordenes/return_webpay', :action => :show, :id => @orden.try(:payment_id), :formats => [:html], :layout => 'layouts/braintree_sin_csrf'
	        end #format.html
                format.json do
                  if @orden
                    render json: { "notificacion_webpay_exitosa: orden es" => @orden.inspect }
                  else
                    render json: { "notificacion_webpay_exitosa" => "intento fallido" }
                  end
	        end #format.json
              end #respond_to
	    end #if orden.present?
          end

          def notificacion_webpay_fallida iduo=nil
            puts "En notificacion_webpay_fallida"
            @orden = ::Comercio::Orden.find_by(:iduo => iduo)

            respond_to do |format|

              format.html do
                @result =  result_hash = {
                  :header => "¡Bah!",
                  :icon => "fail",
                  :message => "Hubo un problema y su pago no se pudo procesar.",
                  :pasarela => "webpay"
                }

                render  :template => 'comercio/ordenes/return_webpay', :action => :show, :id => @orden.try(:payment_id),  :formats => [:html], :layout => 'layouts/braintree_sin_csrf'
               end

              format.json do
                if @orden
                  render json: { "notificacion_webpay_fallida" => "intento exitoso" }
                else
                  render json: { "notificacion_webpay_fallida" => "intento fallido" }
                end
              end
            end
          end


          def notificacion_webpay_fallida_con_reversa iduo=nil

            @orden = ::Comercio::Orden.find_by(:iduo => iduo)

            respond_to do |format|

              format.html do
                @result =  result_hash = {
                  :header => "¡Bah!",
                  :icon => "fail",
                  :message => "Hubo un problema y su compra no ha sido aprobada.",
                  :pasarela => "webpay"
                }

                render  :template => 'comercio/ordenes/return_webpay', :action => :show, :id => @orden.try(:payment_id),  :formats => [:html], :layout => 'layouts/braintree_sin_csrf'
               end

              format.json do
                if @orden
                  render json: { "notificacion_webpay_fallida" => "intento exitoso" }
                else
                  render json: { "notificacion_webpay_fallida" => "intento fallido" }
                end
              end
            end
        end

        def solicitud_fallidamente_tomada presupuesto, colaborador
          ::Waba::Transaccion.new(:colaborador).say_fail presupuesto, colaborador
        end

        def solicitud_exitosamente_tomada presupuesto, colaborador
          ::Waba::Transaccion.new(:colaborador).say_exito presupuesto, colaborador
        end

        #en desuso
        def download_factura
          presupuesto = ::Electrico::Presupuesto.find_by(:remember_token => presupuesto_params[:id]) 

          if presupuesto.usuario
            send_data generate_pdf(presupuesto),
            filename: "presupuesto#{presupuesto.id}_#{presupuesto.usuario.nombre}.pdf", type: "aplication/pdf", disposition: 'inline'
            send_file   "/tmp/presupuesto.pdf", type: "aplication/pdf", status: 200
          else
            #send_file '404.html', type: 'text/html; charset=utf-8', status: 404
            @result =  result_hash = {
               :status => 404,
               :error => "Not Found",
               :header => "¡Ocurrió un Error!",
               :icon => "fail",
               :message => "Algo que escribió a continuación de #{C.domain}/ es una dirección válida en el servidor pero no está el recurso actualmente. Esto es un error de programación y sería muy útil si Ud. se lo dejara saber a alguien de aléctrico."
            }


            @result =  result_hash = {
               :status => 404,
               :error => "Not Found",
               :header => "¡Ocurrió un Error!",
               :icon => "fail",
               :message => "Algo que escribió a continuación de #{C.domain}/ es una dirección válida en el servidor pero no está el recurso actualmente. Esto es un error de programación y sería muy útil si Ud. se lo dejara saber a alguien de aléctrico."
            }
            render  :action => :show, :status => 404, :formats => [:html], :layout => 'layouts/api/error_layout'


	  end
        end

        def notificacion_webpay_anulada token
          respond_to do |format|
            format.html  do
              @orden = ::Comercio::Orden.find_by(:id => token)
              @result =  result_hash = {
                :header => "¡No compró?!",
                :icon => "fail",
                :message => "Lamentamos que haya desistido de su compra.",
                :pasarela => "webpay"
               }
              render  :template => 'comercio/ordenes/return_webpay', :action => :show, :id => @orden.try(:payment_id), :formats => [:html], :layout => 'layouts/braintree'
            end

            format.json do
              if @orden
               render json: { "notificacion_webpay_anulada: orden es" => @orden.inspect }
              else
                render json: { "notificacion_webpay_anulada" => "intento fallido" }
              end
            end

          end
        end

        #en desuso
        def download_boleta
          presupuesto = ::Electrico::Presupuesto.find_by(:remember_token => presupuesto_params[:id])

          if presupuesto.usuario
            doc = Prawn::Revision::Boleta.new("presupuesto")
	    @presupuesto = presupuesto
            doc.tabla(@presupuesto)
	    doc.renderer.min_version(1.6)
            doc.save_as "/tmp/presupuesto.pdf"
            send_file   "/tmp/presupuesto.pdf", :type => 'application/pdf', :disposition => 'inline', :status => 200, :charset => 'utf-8'
	  else 
            #send_file '404.html', type: 'text/html; charset=utf-8', status: 404
	    @result =  result_hash = {
	       :status => 404,
	       :error => "Not Found",
	       :header => "¡Ocurrió un Error!",
	       :icon => "fail",
	       :message => "Algo que escribió a continuación de #{C.domain}/ es una dirección válida en el servidor pero no está el recurso actualmente. Esto es un error de programación y sería muy útil si Ud. se lo dejara saber a alguien de aléctrico."
	    }

            @result =  result_hash = {
               :status => 404,
               :error => "Not Found",
               :header => "¡Ocurrió un Error!",
               :icon => "fail",
               :message => "Algo que escribió a continuación de #{C.domain}/ es una dirección válida en el servidor pero no está el recurso actualmente. Esto es un error de programación y sería muy útil si Ud. se lo dejara saber a alguien de aléctrico."
            }
            render  :action => :show, :status => 404, :formats => [:html], :layout => 'layouts/api/error_layout'


          end
        end

                  #linea.warn "Arreglando un pago en webpay por: #{servicio.precio}"
                 # linea.warn "El pago será confirmado en #{Rails.application.routes.url_helpers.return_webpay_recargar_url(:host =>  C.backend_url)}"

                  #linea.warn "facts es: #{fact.inspect}"
                  #linea.warn "fono es: #{mensaje.from}"

                 # begin
                 #   transaccion = Tbk.new( orden.id, presupuesto.id, servicio.precio,\
                 #                         Rails.application.routes.url_helpers.return_webpay_recargar_url( :host => C.backend_url ))
                 #   linea.warn "Transaccion webpay es #{transaccion.inspect}"
                 #   respuesta = transaccion.create

                 #   linea.warn "La respuesta es #{respuesta}"
                 # rescue StandardError => e
                 #   linea.error "hubo un error al crear la transacción"
                 #   linea.error e.full_message
                 # end
                 # linea.warn "La transaction fue creada es #{transaccion.inspect}"
                 # url_de_pago =  "https://webpay3g.transbank.cl/rswebpaytransaction/api/webpay/v1.0/transactions?token=#{transaccion.token}"
                 # linea.warn "Antes de llamar a enviar_url"


       #El colaboraodr ha seleccionado Recargar desde su whatsapp
       def recargar
          linea.info "En recargar"
          presupuesto = ::Electrico::Presupuesto.find_by(:remember_token => waba_params["id"])

          if not presupuesto.usuario.present?
            linea.warn "No se encontró el usuario del presupuesto"
            self.no_se_encontro_el_usuario
            return
          end

          credito =  ::Comercio::Servicio.creditos.first

          if not credito.present?
            linea.error "No se encontró servicio de crédito"
            self.no_se_encontro_la_visita
            return
          end

          reader = @current_usuario
          linea.info "Procesando el reader"
          if reader.key?('user')
            user= reader['user']
            if user.key?('email')
              email = user['email']
              user = ::User.find_by(:email => email )
              unless user
                self.no_se_encontro_el_usuario
                return
              end
              #usar el email de gestion usuario?
              #email = user.usuario.email
            else
              email = ''
            end
          else
            self.no_se_encontro_el_usuario
            return
          end

          linea.info "Despues de usuario"
          return_url   = C.return_webpay_recargar_url
          cancel_url   = Rails.application.routes.url_helpers.checkout_servicios_url(:host => C.shop_url)
          notify_url   = Rails.application.routes.url_helpers.notificacion_khipu_api_v1_comercio_servicios_url(:host =>  C.backend_url)
          image_url       = C.imagen_visita_url
          listener        = self

          linea.info "Antes de llamar a Compra"
          repositorio     = ::Comercio::OrdenRepositorio

          caso = ::Comercio::Compra::Unitaria::Webpay::Recarga.new(
            repositorio,\
            listener,\
            return_url,\
            cancel_url,\
            image_url,\
            notify_url )

          valid_params = {:id => credito.id, :amp_cliente_id => email, :presupuesto_id => presupuesto.id }
          caso.crea valid_params

          #esto sigue en crear_pago_en_pasarela_webpay o en comprar_ahora_fallido_webpay
        end


        def recarga_paypal
          linea.info "En recargar"
          presupuesto = ::Electrico::Presupuesto.find_by(:remember_token => waba_params["id"])

          if not presupuesto.usuario.present?
            linea.warn "No se encontró el usuario del presupuesto"
            self.no_se_encontro_el_usuario
            return
          end

          credito =  ::Comercio::Servicio.creditos.first

          if not credito.present?
            linea.error "No se encontró servicio de crédito"
            self.no_se_encontro_la_visita
            return
          end

          reader = @current_usuario
          linea.info "Procesando el reader"
          if reader.key?('user')
            user= reader['user']
            if user.key?('email')
              email = user['email']
              user = ::User.find_by(:email => email )
              unless user
                self.no_se_encontro_el_usuario
                return
              end
              #usar el email de gestion usuario?
              #email = user.usuario.email
            else
              email = ''
            end
          else
            self.no_se_encontro_el_usuario
            return
          end

          linea.info "Despues de usuario"

          #WIP
          #Debe usarse paypal
          return_url   = C.return_webpay_recargar_url
          cancel_url   = Rails.application.routes.url_helpers.checkout_servicios_url(:host => C.shop_url)
          notify_url   = Rails.application.routes.url_helpers.notificacion_khipu_api_v1_comercio_servicios_url(:host =>  C.backend_url)
          image_url       = C.imagen_visita_url
          listener        = self

          linea.info "Antes de llamar a Compra"
          repositorio     = ::Comercio::OrdenRepositorio

          caso = ::Comercio::Compra::Unitaria::Webpay::Recarga.new(
            repositorio,\
            listener,\
            return_url,\
            cancel_url,\
            image_url,\
            notify_url )

          valid_params = {:id => credito.id, :amp_cliente_id => email, :presupuesto_id => presupuesto.id }
          caso.crea valid_params

          #esto sigue en crear_pago_en_pasarela_webpay o en comprar_ahora_fallido_webpay

        end

        #El cliente intenta pagar por un presupuesto que ha iniciado.
	#Se creará un servicio para el total del presupuesto.
        #Este servicio no será publicado en shop
        #Hay un problema con esto.
        #Pues se generan servicios que no deseamos ofrecer
        #La otra alternativa es establecer una equivalencia entre un servicio
        #y el costo que se está cobrando en el presupuesto
       
        def pagar
          linea.info "En pagar"
          presupuesto = ::Electrico::Presupuesto.find_by(:remember_token => presupuesto_params[:id]) 

          if not presupuesto.usuario.present?
            linea.warn "No se encontró el usuario del presupuesto"
            self.no_se_encontro_el_usuario
            return
          end

          visita =  ::Comercio::Servicio.find_by(:gtin => C.gtin_visita )

          if not visita.present?
            linea.error "No se encontró la visita con gtin: #{C.gtin_visita}"
            self.no_se_encontro_la_visita 
            return
          end
          linea.info "Despues de visita.nil?"

          reader = @current_usuario

          if reader.key?('user')
            user= reader['user']
            if user.key?('email')
              email = user['email']
              user = Gestion::Usuario.find_by(:email => email )
              unless user
                self.no_se_encontro_el_usuario
                return
              end
            else
              email = ''
            end
          else
            self.no_se_encontro_el_usuario
            return
          end
        
          linea.info "Despues de usuario"
          return_url   = C.return_webpay_aceptar_oferta_url 
          cancel_url   = Rails.application.routes.url_helpers.checkout_servicios_url(:host => C.shop_url) 
          notify_url   = Rails.application.routes.url_helpers.notificacion_khipu_api_v1_comercio_servicios_url(:host =>  C.backend_url)
          image_url       = C.imagen_visita_url  
          listener        = self

          puts "Antes de llamar a Compra"
          repositorio     = ::Comercio::OrdenRepositorio

          caso = ::Comercio::Compra::Unitaria::Webpay::Nominativo::Manual.new(
            repositorio,\
            listener,\
            return_url,\
            cancel_url,\
            image_url,\
            notify_url )

          valid_params = {:id => visita.id, :amp_cliente_id => email, :presupuesto_id => presupuesto.id }
	  puts valid_params

          caso.crea valid_params
           
          #esto sigue en crear_pago_en_pasarela_webpay o en comprar_ahora_fallido_webpay
 	end

        def tomar
          linea.info "En tomar"
          presupuesto = ::Electrico::Presupuesto.find_by(:remember_token => presupuesto_params[:id])

          if not presupuesto.usuario.present?
            linea.warn "No se encontró el usuario del presupuesto"
            self.no_se_encontro_el_usuario
            return
          end
          reader = @current_usuario
          if reader.key?('user')
            usuario= reader['user']
            if usuario.key?('email')
              email = usuario['email']
              usuario = Gestion::Usuario.find_by(:email => email )
              unless usuario
                self.no_se_encontro_el_usuario
                return
              end
            else
              email = ''
            end
          else
            self.no_se_encontro_el_usuario
            return
          end

	  bypass_sign_in usuario&.user if usuario.user
          presupuesto.update(:mandato_aceptado => true)
          caso_de_uso = ::Electrico::CrearSolicitud.new ::Electrico::PresupuestoRepositorio, self
	  caso_de_uso.tomar presupuesto, usuario.user

        end


    def solicitud_exitosamente_tomada solicitud, colaborador=nil
      @presupuesto = solicitud
      ::Waba::Transaccion.new(:colaborador).say_exito @presupuesto, colaborador
      puts "En solicitud exitosamente tomada"
      bypass_sign_in colaborador if colaborador
#      @comment_id = presupuesto_params[:comment_id] #Se usa para mostrar el nuevo registro en la lista de los registros existentes, modificando el DOM.

      respond_to do |format|
	puts "format es:"
	puts format
        format.html{ redirect_to edit_electrico_presupuesto_url(
		:id => solicitud.id,\
	       	:host => C.www_url),\
                :notice => "El presupuesto #{@presupuesto.descripcion} fue tomado exitosamente por #{@presupuesto.colaborador.name}"    }
        format.js { render \
		    :js => "alert('El presupuesto #{@presupuesto.descripcion} fue tomado exitosamente por #{@presupuesto.colaborador.name}');"}
        format.json {head \
                    :no_content, :status => :ok }
      end
    end

    def solicitud_fallidamente_tomada solicitud, colaborador=nil

      begin
        @presupuesto = solicitud
        ::Waba::Transaccion.new(:colaborador).say_fail @presupuesto, colaborador
        linea.info "En solicitud_fallidamente_tomada"
        bypass_sign_in colaborador if colaborador
        cuenta  = ::Comercio::CuentaColaborador.new( colaborador )

        valid_payload = {'user'=>{'email' => colaborador.email}}
        auth_token   = JsonWebToken.encode(:reader => valid_payload )

        @presupuesto.send(:remember_token)
        creditos_disponibles = cuenta.get_creditos_disponibles

        unless creditos_disponibles > 1
          url_de_pago="Ud. tiene solo #{creditos_disponibles} créditos disponibles. Clique en esta dirección para recargar más créditos: #{C.backend_url}/api/v1/electrico/presupuestos/#{@presupuesto.remember_token}/recargar/?auth_token=#{auth_token}"
          ::Waba::Transaccion.new(:colaborador).enviar_url( colaborador.fono, url_de_pago )
        end

      rescue StandardError => e
	linea.error e.inspect
      end

      #los waba llegan aquí convertidos a html
      #por eso los html deben devolver 200
      #de esa forma no se vuelven a genrar en facebook
      respond_to do |format|

        format.html {
          @result =  result_hash = {
            :status => 404,
            :error => cuenta.get_creditos_disponibles > 0 ? "Toma Fallida" : "Saldo Insuficiente",
            :header => "¡Bah!",
            :icon => "fail",
            :message => "No fue posible entregarle esta solicitud."
          }
          render :host => C.www_url,  :action => :show, :status => 200, :formats => [:html], :layout => 'layouts/api/error_layout'
        }
        #format.html {  redirect_to electrico_presupuestos_url(:host => C.www_url),
        #             :notice => "El presupuesto #{@presupuesto.descripcion} no está disponible para cambio de colaborador"  }
        format.js   { render :js => "alert( 'El presupuesto #{@presupuesto.descripcion} no está disponible para cambio de colaborador.');"  }

	format.json { render json: { :status => :ok  } }
	#caso no probado. supuestamente
	#para llegar a aquí se usa hexagonal a CrearSolicitud
	#esto los convierte de json a html
	#https://developers.facebook.com/docs/graph-api/webhooks/getting-started
      end

          #respond_to do |format|
          #  format.json { render json: { :status => :ok  } }
          #end

    end

    def solicitud_no_pudo_ser_tomada_por_error error
      @error = error
      respond_to do |format|
        format.html {
          redirect_to electrico_presupuestos_path, :notice => "Error #{error.inspect}"
        }
        format.js{
          render :js => "alert( 'Ocurrió un error al intentar tomar este presupuesto. Error #{error.inspect}"
        }
      end
    end



        def pagar_visita
          linea.info "En pagar_visita"
          presupuesto = ::Electrico::Presupuesto.find_by(:remember_token => presupuesto_params[:id])

          if not presupuesto.usuario.present?
            linea.warn "No se encontró el usuario del presupuesto"
            self.no_se_encontro_el_usuario
            return
          end

          visita =  ::Comercio::Servicio.find_by(:gtin => C.gtin_visita )

          if not visita.present?
            linea.error "No se encontró la visita con gtin #{C.gtin_visita}"
            self.no_se_encontro_la_visita
            return
          end
          linea.info "Despues de visita.nil?"

          reader = @current_usuario
          if reader.key?('user')
            user= reader['user']
            if user.key?('email')
              email = user['email']
              user = Gestion::Usuario.find_by(:email => email )
              unless user
                self.no_se_encontro_el_usuario
                return
              end
            else
              email = ''
            end
          else
            self.no_se_encontro_el_usuario
            return
          end
          linea.info "Despues de usuario"
          return_url   = C.return_webpay_pagar_visita_url
          cancel_url   = Rails.application.routes.url_helpers.checkout_servicios_url(:host => C.shop_url)
          notify_url   = Rails.application.routes.url_helpers.notificacion_khipu_api_v1_comercio_servicios_url(:host =>  C.backend_url)
          image_url       = C.imagen_visita_url
          listener        = self

          linea.info "Antes de llamar a Compra"
          repositorio     = ::Comercio::OrdenRepositorio

          caso = ::Comercio::Compra::Unitaria::Webpay::Nominativo::Manual.new(
            repositorio,\
            listener,\
            return_url,\
            cancel_url,\
            image_url,\
            notify_url )

          valid_params = {:id => visita.id, :amp_cliente_id => email, :presupuesto_id => presupuesto.id, :factor_descuento => 0.9, :factor_iva => 1.19 }
          caso.crea valid_params

          #esto sigue en crear_pago_en_pasarela_webpay o en comprar_ahora_fallido_webpay
        end


        def pagar_oferta
          puts "En pagar_oferta"
          presupuesto = ::Electrico::Presupuesto.find_by(:remember_token => presupuesto_params[:id])

          if not presupuesto&.usuario.present?
            puts "No se encontró el usuario del presupuesto"
            self.no_se_encontro_el_usuario
            return
          end

          visita =  ::Comercio::Servicio.find_by(:gtin => C.gtin_visita )

          if not visita.present?
            puts "No se encontró la visita con geting #{C.gtin_visita}"
            self.no_se_encontro_la_visita
            return
          end
          puts "Despues de visita.nil?"

          reader = @current_usuario

          if reader.key?('user')
            user= reader['user']
            if user.key?('email')
              email = user['email']
              user = Gestion::Usuario.find_by(:email => email )
              unless user
                self.no_se_encontro_el_usuario
                return
              end
            else
              email = ''
            end
          else
            self.no_se_encontro_el_usuario
            return
          end
          puts "Despues de usuario"
          return_url   = C.return_webpay_aceptar_oferta_url
          cancel_url   = Rails.application.routes.url_helpers.checkout_servicios_url(:host => C.shop_url)
          notify_url   = Rails.application.routes.url_helpers.notificacion_khipu_api_v1_comercio_servicios_url(:host =>  C.backend_url)
          factor_de_descuento = 0.9
          factor_iva = 1.19

          image_url       = C.imagen_visita_url
          listener        = self

          linea.info "Antes de llamar a Compra"
          repositorio     = ::Comercio::OrdenRepositorio

          caso = ::Comercio::Compra::Unitaria::Webpay::Nominativo::Manual.new(
            repositorio,\
            listener,\
            return_url,\
            cancel_url,\
            image_url,\
            notify_url, \
            factor_de_descuento,\
            factor_iva 
          )

          linea.info "Fator de descuento leído desde afuera es: #{caso.factor_de_descuento}"

          valid_params = {:id => visita.id, :amp_cliente_id => email, :presupuesto_id => presupuesto.id }
          caso.crea valid_params

          #esto sigue en crear_pago_en_pasarela_webpay o en comprar_ahora_fallido_webpay
        end



        def crear_pago_en_pasarela_webpay token, pago_url, metodo
          linea.info "En crear_pago_en_pasarela_webpay"
          linea.info "Método es metodo"
          linea.info "url es #{pago_url}?token_ws=#{token}"
          redirect_to "#{pago_url}?token_ws=#{token}", :notice => "Redirigiendo hacia la pasarela de Pago", \
            :protocol => 'https', :port => '443', :method => metodo
        end

        def no_se_encontro_la_visita
           linea.warn "No se encontró la visita"
           @result =  result_hash = {
               :status => 404,
               :error => "Not Found",
               :header => "¡Ocurrió un Error!",
               :icon => "fail",
               :message => "No se encontró un valor actualizado para la Visita. Esto es solucionable si llama al #{C.fono_de_contacto}."
            }
            render  :action => :show, :status => 404, :formats => [:html], :layout => 'layouts/api/error_layout'
        end

        def no_se_encontro_el_usuario
           linea.warn "No se encontró el usuario"
           @result =  result_hash = {
               :status => 404,
               :error => "Not Found",
               :header => "¡Ocurrió un Error!",
               :icon => "fail",
               :message => "No se encontró un valor actualizado para el usuario. Esto es solucionable si llama al #{C.fono_de_contacto}."
            }
            render  :action => :show, :status => 404, :formats => [:html], :layout => 'layouts/api/error_layout'
        end


        def precio_no_ha_sido_fijado_aun
           linea.wran "Precio no ha sido fijado aún"
           @result =  result_hash = {
               :status => 404,
               :error => "Not Found",
               :header => "¡Ocurrió un Error!",
               :icon => "fail",
               :message => "El precio del presupuesto aún no ha sido determinado por el Instalador a Cargo. Espere a que se ponga en contacto con Ud. o llame a alectrico ® al #{C.fono_de_contacto}."
            }
            render  :action => :show, :status => 404, :formats => [:html], :layout => 'layouts/api/error_layout'
        end


	 def comprar_ahora_fallido_webpay orden=nil
            linea.warn "En comprar ahora fallido webpay"
            @result =  result_hash = {
               :status => 404,
               :error => "Not Found",
               :header => "¡Ocurrió un Error!",
               :icon => "fail",
               :message => "Algo que escribió a continuación de #{C.domain}/ es una dirección válida en el servidor pero no está el recurso actualmente. Esto es un error de programación y sería muy útil si Ud. se lo dejara saber a alguien de aléctrico."
            }
            render  :action => :show, :status => 404, :formats => [:html], :layout => 'layouts/api/error_layout'
        end

        def download_pdf
          presupuesto = ::Electrico::Presupuesto.find_by(:remember_token => presupuesto_params[:id])

          linea.info "En download_pdf"
          reader = @current_usuario

          if reader.key?('user')
             user= reader['user']
             if user.key?('email')
               email = user['email']
             else
               email = ''
             end
          end

          if presupuesto.usuario and presupuesto.usuario.email == email
             doc = Prawn::Revision::Boleta.new("presupuesto")
             @presupuesto = presupuesto

             begin
               doc.tabla(@presupuesto)
             rescue Prawn::Errors::IncompatibleStringEncoding => e
               linea.error "Ocurrió un error de encoding al compilar el pdf"
               push_to( presupuesto.colaborador, "El pdf del presupuesto no se pudo compilar, avise al instalador para que corrija los caracteres raros que hayan sido usados, o intente corregirlos Ud. si es que puede.")
               push_to( presupuesto.instalador, "Prawn no compiló pdf del presupuesto, así que no le llegará al cliente, elimine los caracteres que no sean Window 1252 charset tales como los emoticons.")
             end
             doc.renderer.min_version(1.6)
             doc.save_as "/tmp/presupuesto.pdf"
             send_file   "/tmp/presupuesto.pdf", :type => 'application/pdf',\
               :disposition => 'inline', :status => 200, :charset => 'utf-8'
          else
             #send_file '404.html', type: 'text/html; charset=utf-8', status: 404
             @result =  result_hash = {
               :status => 404,
               :error => "Not Found",
               :header => "¡Ocurrió un Error!",
               :icon => "fail",
               :message => "Algo que escribió a continuación de #{C.domain}/ es una dirección válida en el servidor pero no está el recurso actualmente. Esto es un error de programación y sería muy útil si Ud. se lo dejara saber a alguien de aléctrico."
             }

             render  :action => :show, :status => 404, :formats => [:html], :layout => 'layouts/api/error_layout'
           end
        end


        def download_levantamiento_pdf
          levantamiento = ::Electrico::Levantamiento.find_by(:id => presupuesto_params[:levantamiento_id] )
          presupuesto   = ::Electrico::Presupuesto.find_by(:remember_token => presupuesto_params[:id])

          linea.info "En download_levantamiento_pdf"
          reader = @current_usuario

          if reader.key?('user')
             user= reader['user']
             if user.key?('email')
               email = user['email']
             else
               email = ''
             end
          end

          if presupuesto.usuario and presupuesto.usuario.email == email and levantamiento
             begin
                informe = levantamiento.generate_revision_tablero
             rescue Prawn::Errors::IncompatibleStringEncoding => e
               linea.error "Ocurrió un error de encoding al compilar el pdf"
               push_to( presupuesto.colaborador, "El pdf del levantamiento no se pudo compilar, avise al instalador para que corrija los caracteres raros que hayan sido usados, o intente corregirlos Ud. si es que puede.")
               push_to( presupuesto.instalador, "Prawn no compiló pdf del levantamiento, así que no le llegará al cliente, elimine los caracteres que no sean Window 1252 charset, tales como los emoticons.")
             end
             informe.renderer.min_version(1.6)
             informe.save_as "/tmp/levantamiento_#{levantamiento.id}.pdf"
             send_file   "/tmp/levantamiento_#{levantamiento.id}.pdf", :type => 'application/pdf',\
               :disposition => 'inline', :status => 200, :charset => 'utf-8'
          else
             @result =  result_hash = {
               :status => 404,
               :error => "Not Found",
               :header => "¡Ocurrió un Error!",
               :icon => "fail",
               :message => "Algún error ocurrió al generar el levantamiento. Es nuestra culpa!"
             }
             render  :action => :show, :status => 404, :formats => [:html], :layout => 'layouts/api/error_layout'
           end
        end

        #mustra el json de la instalacion
        def instalacion
          ::Electrico::Presupuesto.find_by(:id => presupuesto_params[:id]).instalacion
        end

       def d


        registro = Electrico::Presupuesto.find(params[:id])
        if registro.usuario
         if registro.instalador and not registro.colaborador
            send_data generate_pdf(registro),
            filename: "presupuesto#{registro.id}_#{registro.usuario.nombre}.pdf",type: "aplication/pdf"
           elsif registro.instalador and registro.colaborador
           send_data generate_pdf_colaborador(registro),
           filename: "presupuesto#{registro.id}_#{registro.usuario.nombre}.pdf",
           type: "aplication/pdf"
           end
         end
       end

       def download_unilineal_pdf
          expires_now
          presupuesto = ::Electrico::Presupuesto.find_by(:id => presupuesto_params[:id])
          if presupuesto.circuitos.any?
            begin
              #instalacion= ::D::Instalacion.new
              #instalacion.configurar(1,"")
              #instalacion.tramo_fijo
              #presupuesto.update(:local_comercial => true)
              #instalacion.create(presupuesto)
              instalacion = presupuesto.get_instalacion
              unilineal= ::D::Unilineal.new(instalacion)
            rescue StandardError => e
              linea.error "Ocurrió un error previsto en D::Unilineal.new"
             linea.error e.inspect
            end
            #guarda en tmp/unilineal.pdf
            #linea.info "Antes de llamar a send_data"
            #send_data unilineal.generate_pdf('con_cargas'), :type => 'application/pdf',
            #:disposition => 'inline', :status => 200, :charset => 'utf-8', :filename => "unlineal#{presupuesto.id}.pdf"

            #guarda en tmp/unilineal.pdf
            unilineal.generate_pdf('con_cargas')
            #unilineal.generate_pdf('svg')


            linea.info "Antes de llamar a send_file"
            mountpoint = ENV['IMAGE_MOUNTPOINT'].nil? ? '' : ENV['IMAGE_MOUNTPOINT']
            send_file   "#{mountpoint}/tmp/unilineal.pdf", :type => 'application/pdf',
            :disposition => 'inline', :status => 200, :charset => 'utf-8', :filename => "unlineal#{presupuesto.id}.pdf"
          end
        end


       def download_unilineal_pdf_para_aws#renombrar a donwload_unilineal_pdf
          expires_now
          presupuesto = ::Electrico::Presupuesto.find_by(:id => presupuesto_params[:id])
          if presupuesto.circuitos.any?
            begin
              #instalacion= ::D::Instalacion.new
              #instalacion.configurar(1,"")
              #instalacion.tramo_fijo
              #presupuesto.update(:local_comercial => true)
              #instalacion.create(presupuesto)
              instalacion = presupuesto.get_instalacion
              unilineal= ::D::Unilineal.new(instalacion)
            rescue StandardError => e
              linea.error "Ocurrió un error previsto en D::Unilineal.new"
             linea.error e.inspect
            end
            #guarda en tmp/unilineal.pdf
            unilineal.generate_pdf('con_cargas')
            #unilineal.generate_pdf('svg')

            linea.info "Antes de llamar a send_file"
            #poner /mount si se usa en aws. Eso apuntará a una carpeta dentro de Dockerfile
            mountpoint = ENV['IMAGE_MOUNTPOINT'].nil? ? '/mount' : ENV['IMAGE_MOUNTPOINT']
            send_file   "#{mountpoint}/unilineal.pdf", :type => 'application/pdf',
            :disposition => 'inline', :status => 200, :charset => 'utf-8', :filename => "unlineal#{presupuesto.id}.pdf"
          end
        end

        def download_circuitos_pdf
          presupuesto = ::Electrico::Presupuesto.find_by(:remember_token => presupuesto_params[:id])

          linea.info "En download_circuitos_pdf"
          reader = @current_usuario

          if reader.key?('user')
             user= reader['user']
             if user.key?('email')
               email = user['email']
             else
               email = ''
             end
          end

          linea.info "email"
          linea.info email

          linea.info "user"
          linea.info user.inspect

          if presupuesto.present? and presupuesto.email == email           
            linea.info "Encontrado presupuesto"
            #f presupuesto.usuario.present?
            # linea.info "presupuesto tiene usuario"
            # probado: funciona,deb ese salbado en /mount/tmp
            # hacia allá aputna Rails.root.join('tmp',...
           # pdf = WickedPdf.new.pdf_from_string('<h1>Hello There!</h1>')

            # create a pdf from string using templates, layouts and content option for header or footer
            #WickedPdf.new.pdf_from_string(
            #    render_to_string(:pdf => "pdf_file.pdf", :template => 'templates/pdf.html.erb', :layout => 'pdfs/layout_pdf'), 
            #   :footer => {:content => render_to_string({:template => 'templates/pdf_footer.html.erb', :layout => 'pdfs/layout_pdf'})}
            #            render pdf: "index.pdf",  page_size: "A3",  zoom: 1.5,
         #     template: "electrico/materiales/materiales_unilineal.html.haml",
          #      layout: 'layouts/electrico/pdf.html.haml'
        # end

           #vi _unilineal_completo.html.haml
            #  render_to_string(:pdf      => 'circuitos.pdf', :template => 'electrico/circuitos/_unilineal_completo.html.haml')
            # esto funciona con template pero los render dentro del template no funcionan
            @presupuesto = presupuesto
            pdf = WickedPdf.new.pdf_from_string(
               render_to_string(:pdf      => 'circuitos.pdf', 
                                :template => 'electrico/materiales/materiales_unilineal',
                                :layout   => 'layouts/electrico/pdf')
            )

            # or from your controller, using views & templates and all wicked_pdf options as normal
            #pdf = render_to_string :pdf => "some_file_name"

            # then save to a file
            save_path = Rails.root.join('tmp','circuitos.pdf')
            f= File.open(save_path, 'wb') do |file|
              linea.info "Dentro de file open"
              file << pdf
            end
            #end

            #oc = Prawn::Revision::Boleta.new("presupuesto")
            #presupuesto = presupuesto
            # doc.tabla(@presupuesto)
            #oc.renderer.min_version(1.6)
            #doc.save_as "/tmp/presupuesto.pdf"
          
            linea.info "Antes de llamar a send_file"
            mountpoint = ENV['IMAGE_MOUNTPOINT'].nil? ? '/mount' : ENV['IMAGE_MOUNTPOINT']
            send_file   "#{mountpoint}/tmp/circuitos.pdf", :type => 'application/pdf',\
            :disposition => 'inline', :status => 200, :charset => 'utf-8'
          else
             #send_file '404.html', type: 'text/html; charset=utf-8', status: 404
             @result =  result_hash = {
               :status => 404,
               :error => "Not Found",
               :header => "¡Ocurrió un Error!",
               :icon => "fail",
               :message => "Algo que escribió a continuación de #{C.domain}/ es una dirección válida en el servidor pero no está el recurso actualmente. Esto es un error de programación y sería muy útil si Ud. se lo dejara saber a alguien de aléctrico."
             }

             render  :action => :show, :status => 404, :formats => [:html], :layout => 'layouts/api/error_layout'
           end
        end


        def generate_pdf(registro)
          @registro = registro
          if registro.try(:orden)
            presupuesto = Prawn::Revision::Factura.new("registro")
            presupuesto.tabla(@registro)
            presupuesto.say_hello(@registro)
          else
            presupuesto = Prawn::Revision::Boleta.new("registro")
            presupuesto.tabla(@registro)
          end
          presupuesto.render
        end



        def generate_pdf_colaborador(registro)
          @registro = registro
          presupuesto = Prawn::Revision::Boleta.new("registro")
          presupuesto.tabla(@registro)
          presupuesto.render
        end


        def refund
          response.headers['Access-Control-Allow-Origin']      = request.headers['Origin']
          response.headers['Access-Control-Allow-Credentials'] = true
          response.headers['Access-Control-Expose-Headers']    = 'AMP-Access-Control-Allow-Source-Origin'

          @presupuesto = ::Electrico::Presupuesto.find_by(:remember_token => presupuesto_params[:id]) if presupuesto_params[:id]

          if @presupuesto
            linea.info "Se encontró el presupuesto"
            linea.info @presupuesto.inspect
           # @presupuesto.send(:create_remember_token)
            ps = { :presupuesto_id => @presupuesto.id,\
                   :amount => @presupuesto.lo_cobrado }
            
          else
            ps = { :presupuesto_id => nil, 
                   :amount  => 0 }
          end      

          comprar_ahora= ::Comercio::Compra::Unitaria::Khipu::Repair.new(
            ::Electrico::Presupuesto,\
            self,\
            nil,\
            nil,\
            nil,\
            nil
          )
          linea.info "Antes de llamar a comprar_ahora refund"
          comprar_ahora.refund ps
        end

        def refund_fallido

          respond_to do |format|
            format.json { render json: { :Error => "No se puedo hacer el reembolso"} ,status: :unprocessable_entity  }
          end

        end


        def refund_exitoso

          respond_to do |format|
           format.json { render json: { :Felicitacione => "El reembolso ha sido éxitosamente solicitado a Khipu"}, status: :ok}
          end
        end

        def index
          user = reader['user']
          email = user['email']

          @presupuestos = ::Electrico::Presupuesto.byemail( email )
          @auth_token = presupuesto_params[:auth_token]

          linea.info "Hay #{@presupuestos.count} presupuestos"

          response.headers['Access-Control-Allow-Origin'] = request.headers['Origin']
          response.headers['Access-Control-Allow-Credentials'] = true
          response.headers['Access-Control-Expose-Headers'] = 'AMP-Access-Control-Allow-Source-Origin'
          respond_to do |format|
            if @presupuestos.any? 
              format.json {}
            else
              format.json{ render json: { :Error => "No se encontraron presupuestos"} , status: :unprocessable_entity }
            end
          end
        end

        def commited_tbk_params
          params.permit('token_ws')
        end

	private

        def presupuesto_params
          params.permit!
        end

        def object_params
          params.require(:presupuesto).permit(object: [entry: [changes: [value: [statuses: [:status], contacts: [profile: [:name]], metadata: [:display_phone_number], messages: [:text,:id,:timestamp,:from,:type, image: [:caption,:sha256,:id,:mime_type], location: [:name,:address,:longitude,:latitude,:url], order: [product_items: [:product_retailer_id,:quantity,:item_price,:currency]],context: [:id, :from],button: [:payload,:text],text: [:body]]]]]])
        end

                 # {"email":"F16XzP9kT5ZouoQrGYt+uTNVJ/qYh9mUwce0iVTXvOOoahEq/n1xyBPcswg9SBLEjctDaYytWCaiSeZw2p8o0YFL7Zx6zpRxL60GA8i0/MDczS3kVuPgyPtt350DTLxk","form":{"title":"Mobirise Form","data":[["Name","hhhhh"],["Phone","987654321"],["Email","jjjł@jjj.cl"],["Message","jjjjjj"]]}}#

        def landing_params
          params.permit!
        end

        def waba_params
          if params.has_key?("hub.mode")
            params.permit("hub.mode","hub.challenge", "hub.token", "hub.verify_token")
          elsif params.has_key?(:presupuesto)
#                  presupuesto_params = comunas_params.require(:presupuesto).permit(entry: [changes: [value: [messages: [interactive: [:type, button_reply: [:id, :title]] ] ] ] ])

            params.require(:presupuesto).permit(entry: [changes: [value: [statuses: [:status], contacts: [profile: [:name]], metadata: [:display_phone_number], messages: [:text,:id,:timestamp,:from,:type, video: [:caption,:sha256,:id,:mime_type], image: [:caption,:sha256,:id,:mime_type], location: [:name,:address,:longitude,:latitude,:url], order: [:catalog_id, product_items: [:product_retailer_id,:quantity,:item_price,:currency]], context: [:id, :from], interactive: [:type, button_reply: [:id, :title]], button: [:payload,:text],text: [:body]]]]])
          elsif params.has_key?("auth_token")
            params.permit("auth_token","id")
          else
            respond_to do |format|
              format.json { render json: { :status => :ok  } }
            end
            return

          end
        end
      end
    end
  end
end
