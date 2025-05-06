module Api
  module Amp
    #Este modelo solo reponsde a llamadas remotas de autorización, como las que se encuentran en comercio/servicios/amp_by_example
    class PresupuestosController < AmpController
     include CrearUsuario

  #    before_action :set_autorizaciones, :only => [:autorizacion,:login,:logout]
  #    before_action :set_login       , :only => [:show]
      before_action :set_autorizacion, :only => [:autorizacion]
      before_action :cors, :only => [:autorizacion,:pingback,:login,:logout,:create,:verify]

      def autorizacion #autorizacion es post
        response.headers['AMP-Access-Control-Allow-Source-Origin'] = @origen
        expires_in 3.minutes, :public => true
        respond_to do |format|
          format.json { render json: {"access" => true, "loggedIn" => false} }
        end
      end


      def pingback
        @autorizacion = Autorizacion.new(params[:rid],params[:ref],params[:_],params[:url])
        expires_in 0.minutes, :public => true
        response.headers['AMP-Access-Control-Allow-Source-Origin'] = @origen
        respond_to do |format|
          if @autorizacion.saved
            # Parece que n otma en cuenta el json de retorno
            format.json { render json: {"loggedIn" => true}}
          else
            # Paarece que no toma en cuenta el json de retorno
            format.json { render json: {"loggedIn" => true}}
          end
        end
      end

      def login#login o sign-in
        #Esta action es la de login
        @rid = params_login[:rid] # Es el Reader ID, es como una cookie de Google
        #eturn = params_login[:return]
        respond_to do |format|
          format.html 
        end
      end

      #verifica los argumentos de registro de usuario

      def verify
        expires_in 0.minutes, :public => false
        response.headers['AMP-Access-Control-Allow-Source-Origin'] = @origen
        response.headers['Access-Control-Allow-Credentials'] = true
        response.headers['Access-Control-Allow-Origin'] = @origen

        #resupuesto = Electrico::Presupuesto.new(:usuario => current_user.usuario, :descripcion => params_verify[:descripcion] , :direccion => params_verify[:direccion])

        if current_user
           presupuesto = Electrico::Presupuesto.new(params_verify.merge(:usuario_id => current_user.usuario.id).except(:etapa,:__amp_form_verify))
        else
           presupuesto = Electrico::Presupuesto.new(params_verify.except(:etapa,:__amp_form_verify))
        end

        respond_to do |format|

          #user = ::User.new(:fono => params_verify[:fono],:name => params_verify[:name], :email => params_verify[:email], :password => "123456", :password_confirmation => "123456", :client => true)
          case params_verify[:etapa]
          when "problema"
            valido = presupuesto.valid?(:problema)
          when "direccion"
            valido = presupuesto.valid?(:direccion)
          when "rol"
            valido = presupuesto.valid?(:rol)
          when "visita"
            valido = true
          end

          if valido

            #suario = Gestion::Usuario.new(:fono => params_verify[:fono],:nombre => params_verify[:name], :email => params_verify[:email],:activo => true)
            #f usuario.valid?
            format.json { render json: {"resultado" => "Presupuesto Válido"}, status: :ok}   
            #lse
            # format.json { render json: {"verifyErrors" => usuario.errors.messages.map{|e| {:name =>e[0], :message => e[1].pop}}}, status: :not_found}
           #end
          else
  #	  render json: {"hola" => "como estas"} , status: :not_found 
  #	  raise presupuesto.errors.inspect
            format.json { render json: {"verifyErrors" => presupuesto.errors.messages.map{|e| {:name =>e[0], :message => e[1][0]}}}, status: :not_found}
          end
        end
      end

      def create #solo se llega aquí cuando user y usuario son válidos, pero no se han guardado
        params_verify[:amp_cliente_id]# Es el Reader ID, es como una cookie de Google
        expires_in 0.minutes, :public => true
        response.headers['AMP-Access-Control-Allow-Source-Origin'] = @origen
        response.headers['Access-Control-Allow-Origin'] = @origen
        response.headers['Access-Control-Allow-Credentials'] = true

        etapa = params_verify[:etapa]

        respond_to do |format|
          if signed_in?
            usuario = presupuesto.usuario
            if usuario
              case etapa
                when "problema"
                  presupuesto = Electrico::Presupuesto.find_or_create_by(:amp_cliente_id => params_verify[:amp_cliente_id]) do |presupuesto|
                  
                    presupuesto.descripcion = params_verify[:descripcion] 
                    presupuesto.direccion   = params_verify[:direccion]
                    presupuesto.comuna      = params_verify[:comuna]
                    presupuesto.usuario     = current_user.usuario
                end
                presupuesto.update(params_verify.merge(:usuario_id => current_user.usuario.id).except(:etapa,:__amp_form_verify))
                valido = presupuesto.valid?(:problema)

                linea.info "presupuesto en etapa problema"
                linea.info presupuesto.inspect

              when "direccion"
                presupuesto = Electrico::Presupuesto.find_by(:amp_cliente_id => params_verify[:amp_cliente_id])
                presupuesto.update(params_verify.except(:etapa,:__amp_form_verify))        
                valido = presupuesto.valid?(:direccion)
                linea.info "presupuesto en etapa direccion"
                linea.info presupuesto.inspect
                linea.info params_verify.inspect

              when "tipo_trabajo"

               presupuesto = Electrico::Presupuesto.find_by(:amp_cliente_id => params_verify[:amp_cliente_id])
               #presupuesto.update(params_verify.except(:etapa,:__amp_form_verify))
              # valido = presupuesto.valid?(:tipo_trabajo)
                 valido = true
              when "rol"
                presupuesto = Electrico::Presupuesto.find_by(:amp_cliente_id => params_verify[:amp_cliente_id])
                presupuesto.update(params_verify.except(:etapa, :__amp_form_verify))
                valido = presupuesto.valid?(:rol)
              when "visita"
                presupuesto = Electrico::Presupuesto.find_by(:amp_cliente_id => params_verify[:amp_cliente_id])
                valido = true
              end


              if valido
                format.json { render json: {"resultado" => "Etapa: #{etapa} Presupuesto #{presupuesto.id} Guardado para #{current_user.usuario.nombre} - amp_cliente_id #{params_verify[:amp_cliente_id]}"}, status: :ok}
              else
                linea.error presupuesto.errors.messages.inspect
                format.json { render json: {"verifyErrors" => presupuesto.errors.messages.map{|e| {:name =>e[0], :message => e[1][0]}}}, status: :not_found}
             end

           else

             format.json { render json: {"resultado" => "Está logado #{current_user.email} pero no tiene usuario"}, status: :not_found}

           end
         else
           format.json { render json: {"resultado" => "No hay nadie logado"}, status: :not_found}
         end
       end
     end


    private

      def params_verify
        params.permit(:id, :etapa, :amp_cliente_id, :descripcion, :direccion, :comuna, :__amp_form_verify)
      end
    end
  end
end
