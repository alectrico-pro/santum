#include ApiHelper
module Api
  module V1
    module Comercio
      class ServiciosController < ComercioController
       include Linea 

       if Rails.env.test?
         before_action :cors, except: [ 
	#   :index,\
           :notificacion_onepay_fallida,\
           :notificacion_unitaria_onepay,\
           :notificacion_multiple_onepay,\
           :notificacion_unitaria_webpay,\
           :notificacion_multiple_webpay,\
           :crea_colaborador,\
           :comprar_ahora_exitoso_paypal,\
           :comprar_ahora_fallido_paypal,\
           :comprar_ahora,\
           :notificacion_khipu,\
           :notificacion_repair,\
           :comprar_cart ]
        else
          before_action :cors, except: [
           :notificacion_onepay_fallida,\
           :notificacion_unitaria_onepay,\
           :notificacion_multiple_onepay,\
           :notificacion_unitaria_webpay,\
           :notificacion_multiple_webpay,\
           :crea_colaborador,\
           :comprar_ahora_exitoso_paypal,\
           :comprar_ahora_fallido_paypal,\
           :comprar_ahora,\
           :notificacion_khipu,\
           :notificacion_repair,\
           :comprar_cart ]
	end

	before_action :set_urls, only: [ 
           :notificacion_onepay_fallida,\
	   :comprar_ahora_fallido_webpay,\
           :notificacion_onepay,\
           :notificacion_khipu,\
           :notificacion_repair,\
           :comprar_ahora,\
           :comprar_cart]

        #skip_before_action :cors, only: :notificacion_onepay, if: Rails.env.cucumber?
        begin
          #cucumber cree erróneamnete que hay un filtro not_colaborador_user!
          #pero cuando into sacarlo, rspec alega que no hay tal filtro 
          #no está el filtro de todas formas
          skip_before_action :not_colaborador_user!, only: [:comprar_ahora], if: Rails.env.cucumber?
        rescue
        end

        def index
          response.headers['Access-Control-Allow-Origin'] = request.headers['Origin']
          response.headers['Access-Control-Allow-Credentials'] = true
          response.headers['Access-Control-Expose-Headers'] = 'AMP-Access-Control-Allow-Source-Origin'
          @comercio_servicios = ::Comercio::Servicio.high_low
        end

        #api para los comandos xhr llamados por los controles de precio, tipo de servicio. Estos controles pretenden filtrar el total de los servicios y dejar disponbibles solos los que quiera el usuarios. Están en la front de servicios.
        
        def filtrado
          @todos = ::Comercio::Servicio.where(nil)
          @filtro = servicio_params[:id]
          case @filtro 
          when "low-high-todos-servicios"
            @comercio_servicios = @todos.low_high
          when "low-high-productos-servicios"
            @comercio_servicios = @productos.low_high.productos
          when "low-high-productos"
            @comercio_servicios = @productos.low_high.productos
          when "low-high-instalaciones-servicios"
            @comercio_servicios = @todos.low_high.instalacion
          when "low-high-reparaciones-servicios"
            @comercio_servicios = @todos.low_high.reparacion
          when "low-high-ampliaciones-servicios"
            @comercio_servicios = @todos.low_high.ampliacion
          when "low-high-certificaciones-servicios"
            @comercio_servicios = @todos.low_high.certificacion
          when "low-high-mantenimientos-servicios"
            @comercio_servicios = @todos.low_high.mantenimiento
          when "high-low-todos-servicios"
            @comercio_servicios = @todos.high_low
          when "high-low-productos-servicios"
            @comercio_servicios = @todos.high_low.productos
          when "high-low-productos"
            @comercio_servicios = @todos.high_low.productos
          when "high-low-instalaciones-servicios"
            @comercio_servicios = @todos.high_low.instalacion
          when "high-low-reparaciones-servicios"
            @comercio_servicios = @todos.high_low.reparacion
          when "high-low-ampliaciones-servicios"
            @comercio_servicios = @todos.high_low.ampliacion
          when "high-low-certificaciones-servicios"
            @comercio_servicios = @todos.high_low.certificacion
          when "high-low-mantenimientos-servicios"
            @comercio_servicios = @todos.high_low.mantenimiento
          else
          end

          respond_to do |format|
            format.json { } 
          end
        end

        def show
          #xpires_in 3.minutes, :public => true
          response.headers['Access-Control-Allow-Origin'] = request.headers['Origin']
          @comercio_servicio = ::Comercio::Servicio.find_by(id: params[:id])
          respond_to do |format|
            format.json {}
          end
        end

        #Carrusel de amp que muestra los servicios en una banda inferior llamada you my also want
        def carrusel
          #xpires_in 13.minutes, :public => true
          response.headers['Access-Control-Allow-Origin'] = request.headers['Origin']

          @comercio_servicios = ::Comercio::Servicio.all
          @uno_solo = [1]

          respond_to do |format|
            if @comercio_servicios and @uno_solo
              format.json {}
            end
          end

        end

        def creacion_exitosa_de_orden orden
          render json: orden, status: :ok
        end

        def creacion_fallida_de_orden orden
          render json: {"Error" => orden.errors }  , status: :unprocessable_entity 
        end

        #Compra uno o varios productos
        def comprar_ahora
          
          response.headers['Access-Control-Allow-Origin'] = request.headers['Origin']
          response.headers['Access-Control-Allow-Credentials'] = true
          response.headers['Access-Control-Expose-Headers'] = 'AMP-Access-Control-Allow-Source-Origin'
          linea.info "estoy en comprar_ahora"
          linea.info "servicio params #{servicio_params}"

          case servicio_params[:pasarela]  
          when 'onepay'
            caso = ::Comercio::Compra::Unitaria::Onepay.new( ::Comercio::OrdenRepositorio, self, @return_url, @cancel_url, @picture_url, @notify_url )
          when 'paypal'
            caso = ::Comercio::Compra::Unitaria::Paypal.new( ::Comercio::OrdenRepositorio, self, @return_url, @cancel_url, @picture_url, @notify_url )
          when 'khipu'
            caso = ::Comercio::Compra::Unitaria::Khipu.new( ::Comercio::OrdenRepositorio, self, @return_url, @cancel_url, @picture_url, @notify_url )
          when 'webpay'
            caso = ::Comercio::Compra::Unitaria::Webpay.new( ::Comercio::OrdenRepositorio, self, @return_url, @cancel_url, @picture_url, @notify_url )
          when 'ether'
            caso = ::Comercio::Compra::Unitaria::Ether.new( ::Comercio::OrdenRepositorio, self, @return_url, @cancel_url, @picture_url, @notify_url )


          end

          resultado = caso.crea servicio_params

        end

        def notificacion_unitaria_onepay
          caso =::Comercio::Compra::Unitaria::Onepay.new(::Comercio::OrdenRepositorio, self, @return_url, @cancel_url, @picture_url, nil )
          caso.procesar_notificacion_onepay params
        end

        #Khipu entrega un token para que se averigüe si el pago está conciliado
        #está concilidado cuando su estado es done
        def notificacion_khipu #esta es la notificacion de khipu llamado desde khipu
          
          response.headers['Access-Control-Allow-Origin'] = request.headers['Origin']
          response.headers['Access-Control-Allow-Credentials'] = true
          response.headers['Access-Control-Expose-Headers'] = 'AMP-Access-Control-Allow-Source-Origin'

          linea.info "En notificacion khipu params #{params}"
         
          caso = ::Comercio::Compra::Unitaria::Khipu.new(::Comercio::OrdenRepositorio, self, @return_url, @cancel_url, @picture_url, @notify_url )
          caso.procesar_notificacion params
        
        end

        def notificacion_multiple_webpay
          linea.info "Estoy en notificacion_multiple_webpay"
          caso =::Comercio::Compra::Multiple::Webpay.new(::Comercio::OrdenRepositorio, self, @return_url, @cancel_url, @picture_url, nil )
          caso.procesar_notificacion_onepay params
        end

        def notificacion_unitaria_webpay
          caso =::Comercio::Compra::Multiple::Webpay.new(::Comercio::OrdenRepositorio, self, @return_url, @cancel_url, @picture_url, nil )
          caso.procesar_notificacion_onepay params
        end

        def notificacion_multiple_onepay
          caso =::Comercio::Compra::Multiple::Onepay.new(::Comercio::OrdenRepositorio, self, @return_url, @cancel_url, @picture_url, nil )
          caso.procesar_notificacion_onepay params
        end


        #Khipu entrega un token para anotar una nueva venta que se originó en un lnk externo
        def notificacion_repair #esta es la notificacion de khipu llamado desde khipu
          response.headers['Access-Control-Allow-Origin'] = request.headers['Origin']
          response.headers['Access-Control-Allow-Credentials'] = true
          response.headers['Access-Control-Expose-Headers'] = 'AMP-Access-Control-Allow-Source-Origin'

          linea.info "En notificacion khipu params #{params}"

          caso = ::Comercio::Compra::Unitaria::Khipu::Repair.new(::Comercio::OrdenRepositorio, self, @return_url, @cancel_url, @picture_url, @notify_url )
          caso.procesar_notificacion params

        end


        #Agrega itemes a la orden del cliente actual.
        def addToCart

          response.headers['Access-Control-Allow-Origin'] = request.headers['Origin']
          response.headers['Access-Control-Allow-Credentials'] = true
          response.headers['Access-Control-Expose-Headers'] = 'AMP-Access-Control-Allow-Source-Origin'

           caso =::Comercio::AddToCart.new( ::Comercio::OrdenRepositorio, self )
           caso.crea current_user, params

        end

        #Suma cada precio de items y obtiene un total neto
        def totalForCart
         
          response.headers['Access-Control-Allow-Origin'] = request.headers['Origin']
          response.headers['Access-Control-Allow-Credentials'] = true


          @orden    = ::Comercio::Orden.where(
           :amp_cliente_id => params[:amp_cliente_id],
           :pagado => nil,
           :datos_pago => nil).last

      
	  #@orden = ::Comercio::Orden.mas_reciente.find_or_create_by(:amp_cliente_id => params[:amp_cliente_id])

          respond_to do |format|
            format.json {}
          end
        end

        #Elimina un item y todos los iguales a este, desde el carro
        def dropFromCart
          response.headers['Access-Control-Allow-Origin'] = request.headers['Origin']
                response.headers['Access-Control-Allow-Credentials'] = true
                response.headers['Access-Control-Expose-Headers'] = 'AMP-Access-Control-Allow-Source-Origin'

                @orden    = ::Comercio::Orden.where(
                  :amp_cliente_id => params[:amp_cliente_id],
                  :pagado => nil,
                  :datos_pago => nil).last


                #@orden = ::Comercio::Orden.mas_reciente.find_by(:amp_cliente_id => params[:amp_cliente_id])

                servicio = @orden.servicios.find_by(:id => params[:id])
                linea = servicio.lineas.find_by(:orden => @orden.id)
                linea.destroy! if linea

                servicio = ::Comercio::Servicio.find_by(:id => params[:id])
                if servicio.cantidad_disponible
                  servicio.cantidad_disponible = servicio.cantidad_disponible + 1
                  servicio.save!
                end

          respond_to do |format|
            format.json {  render json: @orden   ,  status: :ok  }
          end
        end

        #Muestra lo ítemes de una orden; la que corresponda al cliente entregado como parámetros
        def cart
          response.headers['Access-Control-Allow-Origin'] = request.headers['Origin']
         response.headers['Access-Control-Allow-Credentials'] = true
               
         #expires_in 3.minutes, :public => true
         @orden    = ::Comercio::Orden.where(
           :amp_cliente_id => params[:amp_cliente_id],
           :pagado => nil,
           :datos_pago => nil).last

         #@orden = ::Comercio::Orden.mas_reciente.find_or_create_by(:amp_cliente_id => params[:amp_cliente_id])
         linea.info "Los params son #{params.inspect}"
         linea.info "Orden es #{@orden.inspect}" if @orden
         linea.info "No fue encontrada la orden" unless @orden

         #if @orden and @orden.pagado?
         if @orden.try(:pagado)
            @orden = ::Comercio::Orden.new(:amp_cliente_id => params[:amp_cliente_id])
           @orden.save(:context => :pago_de_servicio)
          end

          respond_to do |format|
            if @orden
              #puts params[:amp_cliente_id]
              @comercio_servicios = @orden.servicios.all
              #puts "Hay #{@comercio_servicios.count} servicios"
              #@comercio_servicios.each do |c|
              #	puts c.nombre
              #end
              format.json {  }
            else
              format.json {  }
            end
          end
        end

        def notificacion_onepay_fallida payment

          @respuesta = payment
          linea.info "Notificación Fallida en Onepay"
          linea.info "Respuesta: #{payment}"

          @orden = ::Comercio::Orden.find_by(:payment_id => payment.id)
          datos_onepay_json = @orden.datos_pago
          @orden.update(:pagado => true) if @orden

          @orden.update( :datos_pago => payment.to_json )
          linea.info "Orden actualizada #{@orden.inspect}"


          @result =  result_hash = {
            :header => "¡Bah, hubo un Problema!",
            :icon => "fail",
            :message => "Su compra NO ha sido aprobada. "
          }

          linea.info "Comprar Ahora Fallido en Onepay"

          @orden.update(:datos_pago => datos_onepay_json)
          linea.info "Orden antes de ir a checkout #{@orden.inspect}"
   
          @pasarela = "onepay"
          redirect_to checkout_url( payment.id, 'onepay' )

          #render  :layout => 'layouts/braintree', :template => '/comercio/payments/show', :action => :show, :id => payment ? payment.id : params[:occ]
 
        end

        #Esto es llamado luego que el servidor  procese la notificacion
        #la notificacion llega desde khip a procesar_notificacion
        def notificacion_onepay_exitosa payment
          #EN este punto, la orden debe estar rendida, eso se hace con un callback de update en order. LLlamado desde procesar_notificación en Comercio::Compra::Unitaria::Onepay
          @respuesta = payment
          linea.info "Notificación Exitosa en Onepay"
          linea.info "Respuesta: #{payment}"

          @orden = ::Comercio::Orden.find_by(:payment_id => payment.id)
          datos_onepay_json = @orden.datos_pago
          @orden.update(:pagado => true) if @orden

          @orden.update( :datos_pago => payment.to_json )
          linea.info "Orden actualizada #{@orden.inspect}"


          caso_de_uso = ::Comercio::CreaColaborador.new nil, nil
          colaborador = caso_de_uso.crea_colaborador @orden

          ::Operacion::Rendicion.create(
            :pasarela          => :onepay,
            :monto             => @orden.servicios.last.precio,
            :usuario_id        => colaborador.usuario.id,
            :user              => colaborador,
            :tipo_de_operacion => :compra_realizada,
            :orden             => @orden
          )

          sign_out current_user if signed_in?
          sign_in colaborador

          #Se actualiza el dasboard del colaborador para indicar el aumento de saldo#Tal vez sea un poco apresurado. Dado que no se tiene certeza del pago, hasta que se haga la notificación
          if Object.const_defined?('ActionCable')
            ActionCable.server.broadcast(
              "presupuestos:#{CANAL_PRESUPUESTOS_ID}",
              {
                dashfront: ::Electrico::PresupuestosController.render(
                  partial: 'electrico/presupuestos/dashfront_colaborador',
                           locals: { user: colaborador})
                }
             )
          end
          @result =  result_hash = {
            :header => "¡Salió Todo BIEN!",
            :icon => "success",
            :message => "Su compra fue aprobada y su presupuesto se considera pagado. Puede consultar algunos detalles de la transacción, para futura referencia.",
            :pasarela => "onepay"
          }
          @orden.update(:datos_pago => datos_onepay_json)
          linea.info "Orden antes de ir a checkout #{@orden.inspect}"

          #ender  :layout => 'layouts/braintree', :template => '/comercio/payments/show', :action => :show, :id => @payment ? @payment.id : params[:occ]

          @pasarela = "onepay"
          redirect_to checkout_url( payment.id, "onepay" )
        end

        def notificacion_khipu_fallida
          #Ojo, no vuelve al usuario que estaba logado originalmente
          linea.info "Notificación Fallida en Khipu"
          payload = {
            error: "No existe orden de servicio para esta notifiación o ya fue pagada",
            status: 400
          }
          render :json => payload, :status => :bad_request
        end



        #Esto es llamado luego que este sitio procese la notificacion
        #la notificacion llega desde khip a procesar_notificacion
        def notificacion_khipu_exitosa payment
          #EN este punto, la orden debe estar rendida, eso se hace con un callback de update en order. LLlamado desde procesar_notificación en Comercio::Compra::Unitaria::Khipu
          @respuesta = payment
          linea.info "Notificación Exitosa en Khipu"
          linea.info "Respuesta: #{payment}"

          orden = ::Comercio::Orden.find_by(:payment_id => payment.payment_id)

          payload = {
            error: "Todo bien",
            status: 200
          }
          render :json => payload, :status => :ok


        end

        def notificacion_khipu_fallida 
          #Ojo, no vuelve al usuario que estaba logado originalmente
          linea.info "Notificación Fallida en Khipu"
          payload = {
            error: "No existe orden de servicio para esta notifiación o ya fue pagada",
            status: 400
          }
          render :json => payload, :status => :bad_request 
        end

        def aborta_notificacion_khipu
          linea.info "Aviso a Khipu de que no notifique más"
          payload = {
            error: "La orden ya fue notificado",
            status: 400
          }
          render :json => payload, :status => :bad_request
        end

        #Le solicita al colaborador que acepte el contrato y luego uvelve a tomar presupuesto. Solo si acepta
        #Esto es para contratos que solo necesitan firmaarse al pagar la orden
        #No es necesario por ahora
        def tomar_aceptacion_de_mandato orden, presupuesto, colaborador
            orden.update(:mandato_aceptado => true)
            presupuesto.update(:mandato_aceptado => true)
            solicitud = ::Electrico::CrearSolicitud.new Electrico::PresupuestoRepositorio, self
            solicitud.tomar presupuesto, colaborador
        end

        def comprar_ahora_exitoso_en_khipu payment
          linea.info "Comprar Ahora Exitoso en Khipu"
          redirect_url = payment.transfer_url
          begin
            linea.info "redirect_url es #{redirect_url}"
            redirect_to redirect_url #lo manda a pagar a khipu, de allá se debe volver con notificaciones que se reciben en iframe pago_en_proceso
          rescue Exception => e
            linea.info "Ocurrió un error al redirigir a la pasarela de pagos #{e.inspect}"
          end
        end

        def comprar_ahora_fallido_en_khipu payment
          linea.info "Comprar Ahora Fallido en Khipu"
          redirect_to :subdomain  => C.shop_subdomain,
          :controller => '/comercio/servicios',
          :action     => :checkout_error
          @payment = payment if payment
        end

        def comprar_ahora_exitoso_onepay payment
          linea.info "Em comprar ahora exitoso onepay"
          linea.info payment.inspect
          orden = ::Comercio::Orden.find_by(:payment_id => payment.payment_id)
          orden.update(:datos_pago => payment.to_json)
          linea.info "Orden ahora es #{orden.inspect}"
          @precio=orden.servicios.first.precio
          @ott=payment.ott
          @qr="data:image/png;charset=utf-8;base64," + payment.qr_code_as_base64

          render :layout => 'layouts/braintree_sin_csrf'
        end

        def comprar_ahora_fallido_onepay payment
          linea.error "En comprar_ahora_fallido_onebpay"

          @result =  result_hash = {
            :header => "¡Bah!",
            :icon => "fail",
	    :message => "Ocurrió un error. Puede volver a intentar más tarde el pago con Onepay o usar otra de las alternativas de pago disponibles.",
            :pasarela => "onepay"
          }
	  render  :template => '/comercio/payments/show', :action => :show, :id => -1, :layout => 'layouts/braintree_sin_csrf'

        end

        #Esto es solo para paypal
        def comprar_ahora_exitoso payment
          linea.info "Comprar Ahora Exitoso"
          redirect_url = payment.links.find{|v| v.rel == "approval_url" }.href
          begin
            linea.info "redirect_url es #{redirect_url}"
            redirect_to redirect_url #lo manda a pago_execute
          rescue Exception => e
            linea.info "Ocurrió un error al redirigir a la pasarela de pagos #{e.inspect}"
          end
        end

        #Esto es solo para paypal
        def comprar_ahora_exitoso_paypal payment
          linea.info "Comprar Ahora Exitoso Paypal"
          redirect_url = payment.links.find{|v| v.rel == "approval_url" }.href
          begin
            linea.info "redirect_url es #{redirect_url}"
            redirect_to redirect_url #lo manda a pago_execute
          rescue Exception => e
            linea.info "Ocurrió un error al redirigir a la pasarela de pagos #{e.inspect}"
          end
        end

        #Esto es solo para paypal
        def comprar_ahora_fallido_paypal payment
          linea.info "Comprar Ahora Fallido"
          redirect_to :subdomain  => C.shop_subdomain,
          :controller => '/comercio/servicios',
          :action     => :checkout_error
          @payment = payment if payment
        end

        def refund_exitoso payment
          @result =  result_hash = {
            :header => "¡Resultó Bien!",
            :icon => "success",
            :message => "El reembolso de su pago ha sido aprobado. ",
            :pasarela => "paypal"
          }
          linea.info "Refund Exitoso"
        end
      
        def refund_fallido payment
          @result =  result_hash = {
            :header => "¡Bah, hubo un Problema!",
            :icon => "fail",
            :message => "El reembolso de su pago no ha sido aprobado. ",
            :pasarela => "onepay"

          }
          linea.info "Refund Fallido"
        end

        def solicitud_fallidamente_tomada e, colaborador=nil
        #  render json: {"Error" => e }  , status: :unprocessable_entity
        end

        def solicitud_exitosamente_tomada e, colaborador=nil
         # render json: {"Error" => e }  , status: :unprocessable_entity
        end

        def error_enviando_notificacion_de_toma_de_solicitud e, suscripcion
         # render json: {"Error" => e }  , status: :unprocessable_entity
        end

        def creacion_exitosa_de_colaborador colaborador
          respond_to do |format|
            format.json {  render json: colaborador.name.to_json ,  status: :ok  }
          end
        end

        def creacion_fallida_de_colaborador orden
          respond_to do |format|
            format.json {  render json: orden.errors.to_json ,  status: :ok  }
          end
        end

        def crea_colaborador
	  caso_de_uso = ::Comercio::CreaColaborador.new ::Comercio::OrdenRepositorio, self
	  caso_de_uso.crea_colaborador_y_redirecciona params
        end
       
        def crear_pago_en_pasarela_webpay token, pago_url, metodo
          #esto funciona en pago unitario, para pago multiple se usar iframe
          #esto lo cambie pero no lo he probado 
          linea.info "En crear_pago_en_pasarela_webpay"
          redirect_to "#{pago_url}?token_ws=#{token}", :notice => "Redirigiendo hacia Transbank", :protocol => 'https', :port => '443', :method => 'POST'
          return
        end


        def crear_pago_en_pasarela_ether token, pago_url
          #esto funciona en pago unitario, para pago multiple se usar iframe
          #esto lo cambie pero no lo he probado 
          linea.info "En crear_pago_en_pasarela_ether"
          redirect_to "#{pago_url}", :notice => "Redirigiendo hacia Ether", :protocol => 'https', :port => '443', :method => 'POST'
          return
        end


        def comprar_ahora_fallido_webpay  payment_id

          linea.info "En comprar_ahora_fallido_webpay"

          @result =  result_hash = {
            :header => "¡Bah!",
            :icon => "fail",
            :message => "Ocurrió un error.",
            :pasarela => "webpay"
          }

          @orden = ::Comercio::Orden.find_by(:payment_id => payment_id)

          redirect_to checkout_url( -1, 'webpay' )

        end

        def comprar_ahora_exitoso_webpay
          linea.info "En comprar_ahora_exitoso_webpay"
          @result =  result_hash = {
            :header => "¡Resultó Bien!",
            :icon => "success",
            :message => "Enhorabuena, el pago fue aceptado.",
            :pasarela => "webpay"
          }
          redirect_to checkout_url( nil, 'webpay' )
        end

      private 
   
        def servicio_params
          params.permit(:id,"__amp_source_origin", "amp_cliente_id", "pasarela")
        end
 
        def set_urls
          frontend =  C.frontend_url
          backend  =  C.api_url

          case servicio_params['pasarela']

          when 'paypal'
            @return_url = pago_execute_iframe_index_url( :host => backend )
          when 'khipu'
            #return_url debe ser generada dinámicament en la compra,para poder identicar la compra a la vuelta desde khipu
            @return_url = "debe ser generado en el servico"
            @notify_url = notificacion_khipu_api_v1_comercio_servicios_url(:format => :json, :host =>  backend )
          when 'onepay'
            @notify_url = notificacion_unitaria_onepay_api_v1_comercio_servicios_url(:format => :json, :host =>  backend )
            @return_url = notificacion_unitaria_onepay_api_v1_comercio_servicios_url(:format => :json, :host =>  backend )
          when 'webpay'
            @return_url = C.webpay_return_url
          when 'ether'
            @return_url = C.ether_return_url
          end
          @cancel_url  = checkout_servicios_url(:host => frontend )
          @picture_url = "#{C.external_home}/img/compra_de_creditos.png"
        end
      end
    end
  end
end
