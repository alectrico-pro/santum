module Api
  module V1
    class NotificacionesController < V1Controller
      include Linea
        before_action :set_notificacion, only: :destroy

        #Es llamado desde javascript en diferenes casos de uso. 
        #El primero es cuando del lado del cliente haya un usuario autorizado
        #El segundo es cuando del lado del cliente esté un cliente no inscrito
      def destroy

       
        if @notificacion
          @notificacion.destroy
        end
       
        respond_to do |format|
          if current_user and 
            @notificacion and
            current_user.id and 
            current_user.id == @notificacion.user_id
            format.json {render :json =>{"data" => {"success" => 1}}, :status => :ok }
          elsif not current_user
            format.json {render :json =>{"data" => {"success" => 1}}, :status => :ok }
          else
            format.json {head :unauthorized}
          end
        end
      end


      def create
        #user_id = current_user.id
        linea.debug "En create de notificacion"
        linea.debug "vapid_public"
        linea.debug $vapid_public
        linea.debug "vapid_private"
        linea.debug $vapid_private

        if current_user and current_user.id
          #notificacion = ::Electrico::Notificacion.find_or_initialize_by(:user_id => current_user.id)
          notificacion = ::Electrico::Notificacion.find_or_create_by( 
            :auth => notificacion_params[:keys][:auth], 
            :user_id => current_user.id) do |notificacion|
              notificacion.endpoint = notificacion_params[:endpoint]      
	      notificacion.p256dh   = notificacion_params[:keys][:p256dh] 
              notificacion.user_id  = current_user.id
          end
        else
          linea.info "No hay current_user"

           notificacion = ::Electrico::Notificacion.create(
            :auth => notificacion_params[:keys][:auth],
            :user_id => 0,
            :endpoint => notificacion_params[:endpoint],
            :p256dh   => notificacion_params[:keys][:p256dh]
           )


        end
        linea.info( notificacion.inspect )
        notificacion.vapid_public  = $vapid_public
	notificacion.vapid_private = $vapid_private
	

        respond_to do |format|

          if notificacion.valid?
	    notificacion.save
            format.json {
              render json: { data: {success: 1 } }, :status => :ok 
            } 
          else
           format.json {
              render json: { data: {errores: notificacion.errors.to_json } },\
              :status => :not_found #Esperado por javascript
            }
          end
        end
     end

  private

    def set_notificacion
      @notificacion = ::Electrico::Notificacion.find_by(:auth => params[:keys][:auth])
      unless @notificacion
        linea.info "No se encontró notificacion para auth: #{params[:keys][:auth]}"
        raise RequestNotAuthorized
      end
    end

    def notificacion_params
      params.require(:notificacion).permit(\
       :api_key,:expirationTime, :endpoint,\
       :expirationTime, :keys => [:p256dh, :auth])
    end

      def cors
        linea.warn "Cors"
         @origen = params[:__amp_source_origin] || params[":__amp_source_origin"]
        #linea.error "No se ingresó el parámetro :__amp_source_origin" unless @origen

        @origen = request.headers['Origin']

        if URLS_PERMITIDAS
          linea.warn "dominios permitidos #{URLS_PERMITIDAS.inspect}"
          linea.warn "Origen es #{request.headers['Origin']}"
          unless URLS_PERMITIDAS and @origen and @origen.in?( URLS_PERMITIDAS )
            linea.error "#{@origen} no está en la lista permitida"
            raise NotOriginAllowed
            return
          end
        else
          #linea.warn "No se han ingresado los micro servicios permitidos como variable de ambiente"
          raise NotOriginAllowed
          return
        end

        if
          response.headers['AMP-Access-Control-Allow-Source-Origin'] = @origen
          response.headers['Access-Control-Allow-Origin'] = @origen
          response.headers['Access-Control-Expose-Headers'] = 'AMP-Access-Control-Allow-Source-Origin'
          #inea.warn "El origen coincide con el header"
         else
           if request.headers['AMP-Same-Origin']
            #inea.warn "Es Amp-Same-Orgin, adelante"
            #Todo bien, puede proseguir
           else
            #linea.warn "#{@origen} no permitido"
            raise NotOriginAllowed
            return
          end
        end
        #linea.info "Cors aprouved"
      end
    end
  end
end
