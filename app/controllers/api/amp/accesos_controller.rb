module Api
  module Amp
    #Este modelo solo responde a llamadas remotas de autorización, como las que se encuentran en comercio/servicios/amp_by_example
    #Solo se está usando cuando se piden datos de usuario, como al coordinar la venta en shop.[domain]/productos
    #También se usa en designer

    class AccesosController < AmpController
      #Este controlador intenta crear un usuario y también un user
      #También autentica el accesso, con la acción autorizacion
      #Usa pingback luego que está autorizado el acceso, para anotar qué páginas se ven durante las visitas (no lo he implemetnado)
      #logout es llamado por el usuario cuando quiere cerrar la sesion
      #La acción logut redirige al usuario a amp, el que luego vuelve a la acción logout_done
      #Logout done actualiza el estado del usuario a loggedIn false, esto lo vigila la pagina amp que tiene tags de acceso que apropiados estas variables.
      #Verify, acompaña al proceso de creación de usuario.
      #El login, no se hace, aquí, sino que en el controlador de Devise en users
      include ActionController::Cookies
      include CrearUsuario

      before_action :check_cookies, :only => [:autorizacion]
  #    before_action :set_autorizaciones, :only => [:autorizacion,:login,:logout]
  #    before_action :set_login       , :only => [:show]
      before_action :set_autorizacion, :only => [:autorizacion]
      before_action :cors, :only => [:ingresaDatosBancarios, :ingresaDatosDeContacto, :autorizacion,:pingback,:login,:create,:verify], :unless => :html_request?
      before_action :set_locale
    #  layout :select_layout #el layout es diferente para los visitantes y los usuarios

  #    def default_url_options
  #      {:host => C.name_https}
  #    end


      def autorizacion
        response.headers['AMP-Access-Control-Allow-Source-Origin'] = @origen
        response.headers['Access-Control-Allow-Origin'] = request.headers['Origin']
        response.headers['Access-Control-Allow-Credentials'] = true
        response.headers['Access-Control-Expose-Headers'] = 'AMP-Access-Control-Allow-Source-Origin'
        respuesta = {}

        memoria.info "Estado de current_user"
        memoria.info  "Logado" if signed_in?
        memoria.info  "No logado" unless signed_in?
        memoria.info "-------------------"

=begin
        u_rid = ::User.find_by(:rid => params[:rid])
        if u_rid and u_rid.sign_in_count > 0 and not user_signed_in?
          #Esto busca recuperar al usuario que intenta hacer signup con su celular, cuando ya tiene cuenta. Pero funciona un poco extraño en los celulares. DE tal forma que se se hace login del usuario a pesar de que había pedido que le cerraran la sesión.
          #La cookie no está actualizada en este request. No se todavía por qué
          #Entonces llamo al procedimiento de devise para que actualice la cookie en esta combinación de browswe y dispositivo. 
          #En teoría la cookie ya se ha envíado hacia acá en el header y cuando yo haga sign_in, se actualizará y seré enviada al browswer que hizo el request. Quedando logado el usuario en ese browser. 
  #	sign_in u_rid
        end
=end


        
        respond_to do |format|
          unless params[:amp_cliente_id]
            respuesta.merge!( {:amp_cliente_id => "No sé encontró amp_cliente_id"})
            format.json { render json: respuesta, :status => :not_found }
          end
          ##El subscriptor es el usuario que está marcado con el clienteId del dispositivo corriente
          
          #uscriber = ::Cliente.find_by(:amp_cliente_id => params[:amp_cliente_id])
          if current_user and current_user.usuario
            suscriber = current_user

            linea.info "En accessos suscriber es #{suscriber.name}"
            linea.info "El type es #{suscriber.type}"
            linea.info "El usuario es #{suscriber.usuario}"


            respuesta.merge!( {"suscriber" => suscriber.usuario.nombre}) 
            respuesta.merge!( { "access" => true })
            ##El usuario corriente es el usuario actualmente logado en el backend que pasará a estar logado en el publisher site
            respuesta.merge!( {"current_user" => current_user.name} ) if user_signed_in? 
            ##El presupuesto remoto es el último que haya firmado el usuario logado en el backend
            remoto = current_user.usuario.presupuestos.unscope(:order).order(:updated_at).last
            local  = ::Electrico::Presupuesto.find_by(:amp_cliente_id => params[:amp_cliente_id]) 
            presupuesto_remoto = remoto if user_signed_in? and remoto != local and remoto&.circuitos&.any?  #Hay presupuesto remoto solo si el usuario logado tiene uno que no esté como local
            respuesta.merge!( {"presupuesto_remoto" => presupuesto_remoto.id} ) if presupuesto_remoto
            ##El presupuesto local es el presupuesto que actualmente está firmado con el amp_cliente_id del dispositivo en uso
            presupuesto_local =  ::Electrico::Presupuesto.find_by(:amp_cliente_id => params[:amp_cliente_id])
            respuesta.merge!( {"presupuesto_local" => presupuesto_local.id} ) if presupuesto_local
            respuesta.merge!( "items" => presupuesto_remoto.cargas.each.map{|c| {"img" => c.tipo_equipo.img }}) if presupuesto_remoto
            
            respuesta.merge!( "time_stamp" => Time.now)
            respuesta.merge!( "loggedIn" => true ) if user_signed_in?
            respuesta.merge!("dueno_local" => ( presupuesto_local and presupuesto_local.usuario ) ? presupuesto_local.usuario.nombre : "", "dueno_remoto" => ( presupuesto_remoto and presupuesto_remoto.usuario) ? presupuesto_remoto.usuario.nombre : "")
            presupuestos_count = current_user.usuario.presupuestos.count if user_signed_in? and current_user.usuario
            respuesta.merge!( "presupuestos_user_count" => presupuestos_count) if presupuestos_count
            if local
              respuesta.merge!( "direccion" => local.direccion)
              respuesta.merge!( "comprador" => local.usuario&.nombre)
              respuesta.merge!( "fono" => local.usuario&.fono)
              respuesta.merge!( "municipio" => local.comuna)
              respuesta.merge!( "email" => local.usuario&.email)
            end
          else
            sign_out current_user if current_user
            respuesta.merge!("loggedIn" => false)
          end

          m = ::Marketplace::Divisas.new()
          respuesta.merge!( "dolar" => m.get_dolar)
          respuesta.merge!( "mlc"   => m.get_mlc)

          format.json { render json: respuesta }

          memoria.info "Respuesta de autorización"
          memoria.info "#{respuesta}"
          memoria.info "-------------------"

          memoria.info "Estado de current_user"
          memoria.info  "Logado" if signed_in?
          memoria.info  "No logado" unless signed_in?
          memoria.info "-------------------"

         end
      end


      def autorizacion_antigua #autorizacion es post
        response.headers['AMP-Access-Control-Allow-Source-Origin'] = @origen
        response.headers['Access-Control-Allow-Origin'] = request.headers['Origin']
        response.headers['Access-Control-Allow-Credentials'] = true
        response.headers['Access-Control-Expose-Headers'] = 'AMP-Access-Control-Allow-Source-Origin'

  #      expires_in 3.minutes, :public => true
        respond_to do |format|
          #user_signed_in? es de devise, lo preferí antes que current_ser
          subscriber_name = ""
          subscriber = false
          subscriber_presente = ::User.exists?(:amp_cliente_id => params[:amp_cliente_id])
          subscriber = ::User.find_by(:amp_cliente_id => params[:amp_cliente_id]) if subscriber_presente
          subscriber_name = subscriber.name if subscriber_presente

          respuesta = {"access" => true }

          presupuestos_count = 0
          if user_signed_in?
            if current_user.usuario
              #aise current_user.usuario.presupuestos.count.to_s

              presupuestos_count = current_user.usuario.presupuestos.count
              presupuesto = current_user.usuario.presupuestos.first
            end
          else
            presupuesto = ::Electrico::Presupuesto.find_by(:amp_cliente_id => params[:amp_cliente_id])
          end

          #presupuesto = ::Electrico::Presupuesto.find_by(:amp_cliente_id => params[:amp_cliente_id])

          if user_signed_in? and not presupuesto
            #sign_out current_user
          end
          
          if user_signed_in? 
            respuesta.merge!( "loggedIn" => true )
            respuesta.merge!( "current_user" => current_user.name )
            respuesta.merge!( "user_amp_cliente_id" => current_user.amp_cliente_id)
            if current_user.usuario
              respuesta.merge!( "usuario_name" => current_user.usuario.nombre )
              respuesta.merge!( "usuario_amp_cliente_id" => current_user.usuario.amp_cliente_id )
            end
          end

          if presupuesto
            respuesta.merge!( "presupuesto_dispositivo" => presupuesto.id, "presupuesto_local" => true )
            if presupuesto.usuario
               respuesta.merge!( "dueño"                   => presupuesto.usuario.nombre )
            end
            respuesta.merge!( "items" => presupuesto.cargas.each.map{|c| {"img" => c.tipo_equipo.img }})
          end

          if presupuestos_count
            respuesta.merge!( "presupuestos_user_count" => presupuestos_count)
          end

          if subscriber_presente
            respuesta.merge!( "subscriber" => true)
            respuesta.merge!( "subscriber_name" => subscriber.name)
            respuesta.merge!( "subscriber_amp_cliente_id" => subscriber.amp_cliente_id)
          end

          respuesta.merge!( "time_stamp" => Time.now)

          format.json { render json: respuesta }
        end
      end


      def pingback
        @autorizacion = ::Amp::Autorizacion.new(params[:rid],params[:ref],params[:_],params[:url])
        expires_in 0.minutes, :public => true
        response.headers['AMP-Access-Control-Allow-Source-Origin'] = @origen
        response.headers['Access-Control-Allow-Credentials'] = true

        respond_to do |format|
          if @autorizacion.saved
            # Parece que n otma en cuenta el json de retorno
            if user_signed_in?
              format.json { render json: {"loggedIn" => true, "autorizacion"=> "guardada" }}
            else
              format.json { render json: {"loggedIn" => false, "autorizacion"=> "guardada" }}

            end
          else
            # Paarece que no toma en cuenta el json de retorno
            format.json { render json: {"loggedIn" => false, "autorizacion" => "no guardada"}}
          end
        end
      end


      def logout

        u_rid = ::User.find_by(:rid => params[:rid])
        if u_rid and u_rid.sign_in_count > 0 #nd not user_signed_in?
          #La cookie no está actualizada en este request. No se todavía por qué
          #Entonces llamo al procedimiento de devise para que actualice la cookie en esta combinación de browswe y dispositivo. 
          #En teoría la cookie ya se ha envíado hacia acá en el header y cuando yo haga sign_in, se actualizará y seré enviada al browswer que hizo el request. Quedando logado el usuario en ese browser. 
          sign_out u_rid
        end

        if u_rid
          memoria.info "Estado de u_rid"
          memoria.info  "Logado2" if u_rid.sign_in_count > 0
          memoria.info  "No logado" if u_rid.sign_in_count == 0
          memoria.info "-------------------"
        else
          memoria.info "u_rid es nill"
        end


        if signed_in? and current_user.amp?
          #p=::Electrico::Presupuesto.find_by(:amp_cliente_id => params[:amp_cliente_id])
          #p.destroy if p
        end
        sign_out current_user
       
        memoria.info "Estado de current_user"
        memoria.info  "Logado2" if signed_in?
        memoria.info  "No logado" unless signed_in?
        memoria.info "-------------------"

        respond_to do |format|
          format.html{
          @return = params_logout[:return]
          if @return 
            redirect_to @return
          else
             redirect_back fallback_location: root_path
          end
          }

        end
      end

      def logout_done
        response.headers['AMP-Access-Control-Allow-Source-Origin'] = @origen
        @return = params_logout[:return_url]
        respond_to do |format|
          format.json { redirect_to @return}
        end
      end

      #verifica los argumentos de registro de usuario

     def verifyBancarios
        #Busca  todas las combinacines de user y usuario
        expires_in 0.minutes, :public => false
        response.headers['AMP-Access-Control-Allow-Source-Origin'] = @origen
        response.headers['Access-Control-Allow-Credentials']=true
        usuario = nil
        respond_to do |format|

          if params_verify[:amp_cliente_id]
            presupuesto = Electrico::Presupuesto.find_by(:amp_cliente_id => params_verify[:amp_cliente_id])
            if presupuesto
              presupuesto.nombre_banco     = params_verify[:nombre_banco]
              presupuesto.titular_banco    = params_verify[:titular_banco]
              presupuesto.cuenta_banco     = params_verify[:cuenta_banco]
              presupuesto.fono_titular     = params_verify[:fono_titular]
              presupuesto.save
              unless presupuesto.valid?
                m = presupuesto.errors.messages
                format.json { render json: {"objeto" => "presupuesto en verify_bancarios","verifyErrors" => m}, status: :not_found}
                return
              end
            end
            format.json { render json: {:verifyErrors => [{:name => :presupuesto, :message => "No se encontró un presupuesto para este dispositivo"  }] }, status: :not_found}
          end
        end
      end

      def verify
        #Busca  todas las combinacines de user y usuario
        expires_in 0.minutes, :public => false
        response.headers['AMP-Access-Control-Allow-Source-Origin'] = @origen
        response.headers['Access-Control-Allow-Credentials']=true
        usuario = nil
        respond_to do |format|

          if params_verify[:amp_cliente_id]

            usuario = Gestion::Usuario.new(:amp_cliente_id => params_verify[:amp_cliente_id]) do |usuario|
              usuario.nombre = params_verify[:name]
              usuario.email  = params_verify[:email]
              usuario.fono   = params_verify[:fono]
            end

            unless usuario.valid?(:context => params_verify[:etapa])
              #Se trata de anticipar la creación de usuario para informar los errores
              format.json { render json: {"objeto" => "usuario.create en verify #{usuario.email}","verifyErrors" => usuario.errors.messages.map{|e| {:name =>e[0], :message => e[1][0]}}}, status: :not_found}
            end

            user    = ::User.new(:email => params_verify[:email]) do |user|
              user.name  = params_verify[:name]
              user.email = params_verify[:email]
              user.fono  = params_verify[:fono]
              user.password = params_verify[:fono]
              user.password_confirmation= params_verify[:fono]
            end

            user.save
            usuario.save

            if user.valid? and usuario.valid?
              usuario.update({:user_id => user.id,:activo => true})
            end

            unless user.valid?(:context => params_verify[:etapa])
              #Se anticipa la creación de user para informar los errores
              m = user.errors.messages
              format.json { render json: {"objeto" => "user.create en verify #{user.email}","verifyErrors" => m}, status: :not_found}
            end

            usuario.update(:user_id => user.id)

            if usuario and user and not usuario.user == user

              #ESto significa que usuario y user existen y que son válidos.
              #Pero no puedo conectarlos porque, para eso necesitaría asignarle un id. Y lo que trato de evitar es que se gaste tiempo creando registros en la base de datos.
              format.json { render json: {"resultado" => "User y Usuario Encontrados pero no conectados #{usuario.nombre} - amp_cliente_id #{params_verify[:amp_cliente_id]}"}, status: :ok}

            elsif usuario and user and  usuario.user == user
              
              format.json { render json: {"resultado" => "User y Usuario Encontrados y conectados #{usuario.nombre} - amp_cliente_id #{params_verify[:amp_cliente_id]}"}, status: :ok}
            elsif (usuario) and (not user) and (not usuario.user)

             format.json { render json: {"resultado" => "User inexistente para el email solicitado #{params_verify[:email]} - Usuario nombre #{usuario.nombre} - Usuario amp_cliente_id #{usuario.amp_cliente_id} - amp_cliente_id solicitado #{params_verify[:amp_cliente_id]} - No hay Usuario.user"}, status: :not_found}

            elsif (usuario) and (not user) and (usuario.user)

            #ormat.json { render json: {:verifyErrors => [{:name => :email, :message => "Dispositivo no está relacionado con email #{params_verify[:email]}"  }] , "resultado" => "User inexistente para el email solicitado #{params_verify[:email]} - Usuario nombre #{usuario.nombre} - Usuario amp_cliente_id #{usuario.amp_cliente_id} - amp_cliente_id solicitado #{params_verify[:amp_cliente_id]} - Usuario.user es #{usuario.user.email}"}, status: :not_found}


            format.json { render json: {:verifyErrors => [{:name => :email, :message => "Este dispositivo no usa #{params_verify[:email]}"  }] }, status: :not_found}


             #format.json { render json: {"resultado" => "Usuario #{usuario.nombre} - clienteId=#{usuario.amp_cliente_id} no tiene user - amp_cliente_id #{params_verify[:amp_cliente_id]}"}, status: :not_found}

            elsif user and not usuario
              format.json { render json: {"resultado" => "User #{user.name} no tiene usuario- amp_cliente_id #{params_verify[:amp_cliente_id]}"}, status: :not_found}
            end
          end
        end
      end


      def verify2
        expires_in 0.minutes, :public => false
        response.headers['AMP-Access-Control-Allow-Source-Origin'] = @origen

        usuario = nil
        respond_to do |format|

          if params_verify[:amp_cliente_id] 

            usuario = Gestion::Usuario.find_by(:amp_cliente_id => params_verify[:amp_cliente_id])
            user    = ::User.find_by(:email => params_verify[:email])



=begin
          if user
            format.json { render json: {"resultado" => "User email #{user.email}, solicitado #{params_verify[:email]} - Usuario nombre #{usuario.nombre} - Usuario amp_cliente_id #{usuario.amp_cliente_id} - amp_cliente_id solicitado #{params_verify[:amp_cliente_id]} - Usuario.user es #{usuario.user.email}"}, status: :ok}
          else
            format.json { render json: {"resultado" => "User inexistente para el email solicitado #{params_verify[:email]} - Usuario nombre #{usuario.nombre} - Usuario amp_cliente_id #{usuario.amp_cliente_id} - amp_cliente_id solicitado #{params_verify[:amp_cliente_id]} - Usuario.user es #{usuario.user.email}"}, status: :ok}

          end
=end

          else
            format.json { render json: {"resultado" => "No se encontró el parámetros amp_cliente_id"}, status: :not_found}

          end

=begin
          if usuario and user and not usuario.user == user
            format.json { render json: {"resultado" => "User y Usuario Encontradospero no conectados #{usuario.nombre} - amp_cliente_id #{params_verify[:amp_cliente_id]}"}, status: :not_found}

          elsif usuario and user and  usuario.user == user
            #Es el usuario
            format.json { render json: {"resultado" => "User y Usuario Encontrados y conectados #{usuario.nombre} - amp_cliente_id #{params_verify[:amp_cliente_id]}"}, status: :ok}
          elsif (usuario) and (not user) and (not usuario.user)

           format.json { render json: {"resultado" => "User inexistente para el email solicitado #{params_verify[:email]} - Usuario nombre #{usuario.nombre} - Usuario amp_cliente_id #{usuario.amp_cliente_id} - amp_cliente_id solicitado #{params_verify[:amp_cliente_id]} - No hay Usuario.user"}, status: :not_found}

          elsif (usuario) and (not user) and (usuario.user)

          #ormat.json { render json: {:verifyErrors => [{:name => :email, :message => "Dispositivo no está relacionado con email #{params_verify[:email]}"  }] , "resultado" => "User inexistente para el email solicitado #{params_verify[:email]} - Usuario nombre #{usuario.nombre} - Usuario amp_cliente_id #{usuario.amp_cliente_id} - amp_cliente_id solicitado #{params_verify[:amp_cliente_id]} - Usuario.user es #{usuario.user.email}"}, status: :not_found}


          format.json { render json: {:verifyErrors => [{:name => :email, :message => "Este dispositivo no usa #{params_verify[:email]}"  }] "}, status: :not_found}


           #format.json { render json: {"resultado" => "Usuario #{usuario.nombre} - clienteId=#{usuario.amp_cliente_id} no tiene user - amp_cliente_id #{params_verify[:amp_cliente_id]}"}, status: :not_found}

          elsif user and not usuario
            format.json { render json: {"resultado" => "User #{user.name} no tiene usuario- amp_cliente_id #{params_verify[:amp_cliente_id]}"}, status: :not_found}




          else
=end

            user = ::User.find_or_create_by(:email => params_verify[:email]) do |user|
              user.fono = params_verify[:fono]
              user.name = params_verify[:name]
              user.password = params_verify[:fono]
              user.password_confirmation = params_verify[:fono]
              user.amp = true
            end

            if user.valid?
              linea.info "user es valid"
             #usuario = Gestion::Usuario.find_or_create_by({:fono => params_verify[:fono],:nombre => params_verify[:name], :email => params_verify[:email]})
              usuario = Gestion::Usuario.find_or_create_by(:email => params_verify[:email])
              usuario.nombre = params_verify[:name]
              usuario.fono   = params_verify[:fono]
              usuario.active = true
              usuario.user_id = user.id
              usuario.save
              if usuario.valid?(:acceso_amp)
                linea.info "usuario es valid"
                linea.info usuario.inspect
                sign_out current_user if signed_in?
                sign_in user
                linea.info "Ahora debe estar logado"
                format.json { render json: {"resultado" => "User y Usuario Válidos y ahora está logado"}, status: :ok}   

              else
                linea.info "usuario no es válido"
                format.json { render json: {"verifyErrors" => usuario.errors.messages.map{|e| {:name =>e[0], :message => e[1][0]}}}, status: :not_found}
              end
            else
              linea.info "user no es válido"
              format.json { render json: {"verifyErrors" => user.errors.messages.map{|e| {:name =>e[0], :message => e[1][0]}}}, status: :not_found}
            end

        end
      end

      def ingresaDatosDeContacto
        expires_in 0.minutes, :public => true
        response.headers['AMP-Access-Control-Allow-Source-Origin'] = @origen
        response.headers['Access-Control-Allow-Credentials'] = true

        presupuesto = Electrico::Presupuesto.find_or_create_by(:amp_cliente_id => params_verify[:amp_cliente_id]) do |presupuesto|
          presupuesto.name            = params_verify[:name]
          presupuesto.fono            = params_verify[:fono]
          presupuesto.direccion       = params_verify[:direccion]
          presupuesto.comuna          = params_verify[:comuna]
          presupuesto.email           = params_verify[:email]
          presupuesto.nombre_banco    = params_verify[:nombre_banco]
          presupuesto.titular_banco   = params_verify[:titular_banco]
          presupuesto.cuenta_banco    = params_verify[:cuenta_banco]
          presupuesto.es_comercio     = true
          presupuesto.es_electricidad = false
        end

        presupuesto.update({:fono => params_verify[:fono], :email => params_verify[:email], :direccion => params_verify[:direccion], :name => params_verify[:name], :comuna => params_verify[:comuna], :es_comercio => true, :es_electricidad => false})

        linea.info presupuesto.inspect


        respond_to do |format|
          format.json { render json: {"objeto" => "presupuests.inspect"}, status: :ok}
        end
      end


      def ingresaDatosBancarios
        expires_in 0.minutes, :public => true
        response.headers['AMP-Access-Control-Allow-Source-Origin'] = @origen
        response.headers['Access-Control-Allow-Credentials'] = true

        presupuesto = Electrico::Presupuesto.find_or_create_by(:amp_cliente_id => params_verify[:amp_cliente_id]) do |presupuesto|
          presupuesto.nombre_banco     = params_verify[:nombre_banco]
          presupuesto.titular_banco    = params_verify[:titular_banco]
          presupuesto.cuenta_banco     = params_verify[:cuenta_banco]
          presupuesto.fono_titular     = params_verify[:fono_titular]

        end

        presupuesto.update({:fono_titular => params_verify[:fono_titular], :nombre_banco => params_verify[:nombre_banco], :titular_banco => params_verify[:titular_banco], :cuenta_banco => params_verify[:cuenta_banco]})

        linea.info presupuesto.inspect


        respond_to do |format|
          format.json { render json: {"objeto" => "presupuests.inspect"}, status: :ok}
        end
      end


      def create #solo se llega aquí cuando user y usuario son válidos, pero no se han guardado
        expires_in 0.minutes, :public => true
        response.headers['AMP-Access-Control-Allow-Source-Origin'] = @origen
        response.headers['Access-Control-Allow-Credentials'] = true

        respond_to do |format|
          user    = ::User.new(:email => params_verify[:email]) do |user|
              user.name     = params_verify[:name]
              user.fono     = params_verify[:fono]
              user.email    = params_verify[:email]
              user.password = params_verify[:fono]
              user.password_confirmation = params_verify[:fono]   
              user.amp    = true
          end


          if user.valid?
          #  user.confirmed_at = Time.now
            user.save
          else
            format.json { render json: {"objeto" => "user", "verifyErrors" => user.errors.messages.map{|e| {:name =>e[0], :message => e[1][0]}}}, status: :not_found}
          end

          #ser.update(:name => params_verify[:name], :fono => params_verify[:fono], :email => params_verify[:email],:amp => true)

          unless user.save
            format.json { render json: {"objeto" => "user","verifyErrors" => user.errors.messages.map{|e| {:name =>e[0], :message => e[1][0]}}}, status: :not_found}
          end


          #busca y si no encuentra, crea el usuario adecuado a lo pedido
          usuario = Gestion::Usuario.create(:amp_cliente_id => params_verify[:amp_cliente_id]) do |usuario|
             usuario.nombre   = params_verify[:name]
             usuario.fono     = params_verify[:fono]
             usuario.email    = params_verify[:email]
             usuario.amp_cliente_id = params_verify[:amp_cliente_id]
             usuario.user     = user
             usuario.activo   = true
          end

          unless usuario.valid?(context: :acceso_amp)
            format.json { render json: {"objeto" => "usuario.valid", "verifyErrors" => usuario.errors.messages.map{|e| {:name =>e[0], :message => e[1][0]}}}, status: :not_found}
          end

          #actualiza considerando la posibilidad de que el registro encontrado sea diferente del ingresado por el usuario
          usuario.update(:nombre => params_verify[:name], :fono => params_verify[:fono], :email => params_verify[:email],:user => user, :activo => true,:amp_cliente_id => params[:amp_cliente_id])

          unless usuario.save(context: :acceso_amp)
            format.json { render json: {"objeto" => "usuario.save usuario.email #{usuario.email}","verifyErrors" => usuario.errors.messages.map{|e| {:name =>e[0], :message => e[1][0]}}}, status: :not_found}
          end

          sign_out current_user if signed_in?
          sign_in user 
          

          if signed_in?
            response.headers['AMP-Access-Control-Allow-Source-Origin'] = @origen
            response.headers['AMP-Redirect-To'] = checkout_servicios_url
            response.headers["Access-Control-Exposure-Headers"] =  "AMP-Redirect-To"
            format.json { render json: {"resultado" => "#{current_user.email} está logado"}, status: :ok}
          else
            format.json { render json: {"resultado" => "#{user.email} no está logado"}, status: :ok}
          end

=begin
          if usuario and user and not usuario.user
            format.json { render json: {"resultado" => "User y Usuario Encontradospero no conectados #{usuario.nombre} - amp_cliente_id #{params_verify[:amp_cliente_id]}"}, status: :ok}

          elsif usuario and user and  usuario.user == user
            #Es el usuario
            format.json { render json: {"resultado" => "User y Usuario Encontradosy conectados #{usuario.nombre} - amp_cliente_id #{params_verify[:amp_cliente_id]}"}, status: :ok}
          elsif usuario and not user

            format.json { render json: {"resultado" => "Usuario #{usuario.nombre} no tiene user - amp_cliente_id #{params_verify[:amp_cliente_id]}"}, status: :not_found}

          elsif user and not usuario
            format.json { render json: {"resultado" => "User #{user.name} no tiene Usuario - amp_cliente_id #{params_verify[:amp_cliente_id]}"}, status: :not_found}
          end

=end
=begin
          user = ::User.new(:fono => params_verify[:fono],:name => params_verify[:name], :email => params_verify[:email], :password => "123456", :password_confirmation => "123456", :client => true)


          if user.valid?#verifica que user tenga los datos correctos y verifica que no tenga existencia previa como modelo
            usuario = Gestion::Usuario.new(:fono => params_verify[:fono],:nombre => params_verify[:name], :email => params_verify[:email],:amp_cliente_id => params_verify[:amp_cliente_id], :activo => true,:user => user)
            #se crea un nuevo usuario para asociarlo al user 
            if usuario.valid?
              if usuario.save(context: :acceso_amp)
                #Se guarda y se reporta todo ok
                format.json { render json: {"resultado" => "User y Usuario Guardados #{usuario.nombre} - amp_cliente_id #{params_verify[:amp_cliente_id]}"}, status: :ok}
              else
                #No se pudo crear usuario debido a que ya existía otro con el mismo amp_cliente_id (puede haber otros errores)
                if usuario.errors[:amp_cliente_id] #El error es porque se ha intentado aagregar un usuario extra con el mismo amp_cliente_id. Se puede aprovechar la garantía de que amp_cliente_id es único para cada dispositivo y buscarlo. Luego se debe modificar para tener los datos que se ingresaron ahora
                  usuario = Gestion::Usuario.find_by(:amp_cliente_id => params_verify[:amp_cliente_id])
                  if usuario
                     usuario.update(:nombre => params_verify[:name], :fono => params_verify[:fono], :email => params_verify[:email])
                     if usuario.valid?
                        format.json { render json: {"resultado" => "Usuario Actualizado #{usuario.nombre} - amp_cliente_id #{params_verify[:amp_cliente_id]}"}, status: :ok}

                     else
                       #-Hubo problemas al validar usuario
                       if usuario.errors[:email] #duplicado
                         format.json { render json: {"verifyErrors" => [:name => :email, :message => "Email de usuario duplicado"]}, status: :not_found}
                       else
                         format.json { render json: {"verifyErrors" => [:name => :email, :message => "?Email de usuario duplicado"]}, status: :not_found}

                        #rmat.json { render json: {"verifyErrors" => user.errors.messages.map{|e| {:name =>e[0], :message => e[1].pop}}}, status: :not_found}
                      end


                       format.json { render json: {"verifyErrors" => [:name => "amp_cliente_id", :message => "No fue posible actualizar attributes del usuario"]}}
                     end
                  else
                    format.json { render json: {"verifyErrors" => [:name => "amp_cliente_id", :message => "No fue posible encontrar otro amp_cliente_id"]}}
                  end
                else
                  format.json { render json: {"verifyErrors" => usuario.errors.messages.map{|e| {:name =>e[0], :message => e[1].pop}}}, status: :not_found}
                end
              end
            else
              if usuario.errors[:email] #duplicado
                format.json { render json: {"verifyErrors" => [:name => :email, :message => "Email de usuario duplicado"]}, status: :not_found}
              else
                format.json { render json: {"verifyErrors" => [:name => :email, :message => "?Email de usuario duplicado"]}, status: :not_found}

                #rmat.json { render json: {"verifyErrors" => user.errors.messages.map{|e| {:name =>e[0], :message => e[1].pop}}}, status: :not_found}
              end
                format.json { render json: {"verifyErrors" => usuario.errors.messages.map{|e| {:name =>e[0], :message => e[1].pop}}}, status: :not_found}
            end
          else
            #-Hubo problemas al validar user
            if user.errors[:email] #duplicado
              format.json { render json: {"verifyErrors" => [:name => :email, :message => "Email de user duplicado"]}, status: :not_found}
            else
              format.json { render json: {"verifyErrors" => [:name => :email, :message => "?Email de user duplicado"]}, status: :not_found}

              #rmat.json { render json: {"verifyErrors" => user.errors.messages.map{|e| {:name =>e[0], :message => e[1].pop}}}, status: :not_found}
            end

      
          end
=end
        end
      end



    private


      def set_locale
        if signed_in?
          if current_user.type == "Instalador" or current_user.instalador?
            I18n.locale = :instalador
          elsif current_user.client?
            I18n.locale = :cliente
          elsif current_user.profesor?
            I18n.locale = :profesor
          elsif current_user.amp?
            I18n.locale = :amp
          else
            I18n.locale = :es_Cl
          end
        else
          I18n.locale = :amp
        end
      end

      def select_layout
       'layouts/amp/accesos/amp' unless current_user
       false if current_user and current_user.amp?
      end

      def html_request?
        request.format.html?
      end

      def params_verify
        params.permit(:nombre_banco, :titular_banco, :cuenta_banco, :fono_titular, :direccion, :comuna, :fono,:name, :email,:amp_cliente_id, :__amp_form_verify)
      end

      def params_login
        params.permit(:rid, :url, :return,:__amp_form_verify)
      end

      def params_logout
        params.permit(:return_url,:return)
      end

      def params_autorizacion
        params.permit(:rid,:ref,:_,:url)
      end

      def set_autorizacion
        @autorizacion = ::Amp::Autorizacion.new(params[:rid],params[:ref],params[:_],params[:url])
      end
    end
  end
end
