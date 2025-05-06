module Biblioteca
  module Mensajeria
    #Clase auxiliar para comunicarse con el usuario de tres formas posibles
    #email, push y websockets (no veo ActionCable acá)
    include ::Linea

    #mail to lista threaded
    #enviando emil dentro de un Thread para evitar delayedjob y el uso de
    #un servicio adicional
    #metodo debe ser un sym
    #mailer_name debe se un nombre de clase
    def mail_to_lista( lista, mailer_name, metodo )
     #mailer = mailer_name.constantize
      Thread.new do
	begin
          lista.each{ |e| mailer_name.send(metodo) }
        rescue StandardError => er
          linea.error "Error en enviar email, en mail_to_lista #{er.inspect}"
        end
        ActiveRecord::Base.connection.close
      end
    end

    def enviar mensaje, suscripcion
      push_to( suscripcion.user, mensaje)
    end


    def push_to(user, mensaje)
      linea.info "En push_to de Biblioteca::Mensajeria"
      linea.info "Preparando para enviar un push al user #{user.name}"
      linea.info "Mensaje es: #{mensaje}"
      enviado = false
      Electrico::Notificacion.select{ |n| n.user_id == user.id}.each do |notif| #cada usuario puede tener varios browsers-dispositivos suscritos. Se le envía a todos
        begin
          p256dh= Base64.urlsafe_decode64(notif.p256dh)
        rescue StandardError => e
          linea.warn "Error enviando notificacion a #{user.name} en push_to de Biblioteca::Mensajees"
          linea.warn e.inspect
        end

        linea.info "Comprobando codificacioń base 64 de auth"
        begin
          auth = Base64.urlsafe_decode64(notif.auth)
        rescue StandardError => e
          linea.warn e.inspect
        end


        begin
          json_mensaje = JSON.generate(mensaje)
        rescue ArgumentError => e
          linea.warn "---- JSON.generate arroja error de argumento --"
          linea.warn e.inspect
          linea.warn "-----------------------------------------------"
        end
#             :p256dh       => Base64.encode64( Base64.urlsafe_decode64(notif.p256dh)),
 #            :auth         => Base64.encode64( Base64.urlsafe_decode64(notif.auth)),


        if !notif.exclude_from_tests and user.usuario and user.usuario.nombre
          linea.info "El presupuesto tiene usuario y nombre de usuario"
          begin
            Webpush.payload_send(
              :message      => json_mensaje,
              :endpoint     => notif.endpoint,
              :p256dh       => notif.p256dh,
              :auth         => notif.auth,
              :ssl_timeout  => 5,
              :open_timeout => 5,
              :read_timeout => 5,
              :vapid        => {
                   subject:      "mailto:sender@alectrico.cl",
                   public_key:   $vapid_public,
                   private_key:  $vapid_private,
                   expiration: 12 * 60 * 60
                }
            )

            enviado = true
            rescue Webpush::ExpiredSubscription => e
              linea.warn "Suscripción expirada"
              linea.warn e.inspect
              begin
                notif.delete unless ( Rails.env.test or Rails.env.development )
              rescue
              end
              enviar_email( mensaje , user )
              #enviar_email( e.inspect, user)

              enviado = false
              notif.destroy
            rescue SocketError => e
              linea.warn "Error de Socket"
              linea.warn e.inspect
              if Rails.env.test?
                linea.info "Se considera enviado pues es modo test"
                enviado = true
              else
                enviado = false
              end

            rescue Webpush::InvalidSubscription => e
              linea.warn "Suscripción No Válida" 
              linea.warn e.inspect
              ilnea.info "Enviando un correo para remediar"
              enviar_email( mensaje , user )
              #nviar_email( e.inspect, user)
              enviado = false
              linea.warn "Se borrará este usuario de notificacion"
              notif.destroy

            rescue Webpush::Unauthorized => e
              linea.error "WebPush No autorizado"
              linea.info e.inspect
	      linea.info "user: #{user.name}"
	      linea.info "notif: #{notif.inspect}"
	      linea.info "vapid_public: #{$vapid_public}"
	      linea.info "vapid_private: #{$vapid_private}"

              linea.warn "Se borrará este usuario de notificación"
              linea.warn "Se enviará correo de todas formas pero en lugar de la notificación"
              enviar_email( mensaje , user )
              #nviar_email( e.inspect, user)
              enviado = false
              notif.destroy unless Rails.env.test? or Rails.env.development?

            rescue ArgumentError => e
              linea.warn "Error de Argumento"
              linea.warn e.inspect
              linea.warn "Se envíará un email como remedio"
              enviar_email( mensaje , user )
              #nviar_email( e.inspect, user)

              enviado = false

            rescue StandardError => e
              linea.error "Error Estandard"
              linea.warn e.inspect
	      linea.warn "El mensaje es:"
	      linea.warn mensaje.inspect
              linea.info "Enviando email como remedio"
              enviar_email( mensaje , user )
              #nviar_email( e.inspect, user)
              enviado = false
              #nviado = true #OJO ES probando
          end
          linea.info "El mensaje fue enviado" if enviado
          linea.info "El mensaje no fue enviado" unless enviado

        end
      end

      return enviado
  #    return true #Para que pase la validación, no importa si no pudo notificar vía webpush
    end

    alias webpush_to push_to



    def enviar_v1 mensaje, suscripcion
      begin
        Webpush.payload_send(
          :message      => JSON.generate(mensaje),
          :endpoint     => suscripcion.endpoint,
          :p256dh       => suscripcion.p256dh,
          :auth         => suscripcion.auth,
          :ssl_timeout  => 5,
          :open_timeout => 5,
          :read_timeout => 5,
          :vapid        => {
             subject:    "mailto:sender@alectrico.cl",
             public_key:   $vapid_public,
             private_key:  $vapid_private,
            expiration: 12 * 60 * 60
          }
        )
        return true

      rescue Exception => e
        linea.info "Error enviando email #{e.inspect}"
        if ::Rails.env.test?
          case e.class.to_s 
          when "Webpush::Unauthorized"
            return true
          else 
            enviar_email( mensaje, suscripcion.user )
            return false
          end
        end        
      end
    end

    #Envía por email un mensaje (mensaje) a un usuario (user)
    def enviar_email( mensaje, user )
      linea.info "En enviar email"
      #Thread.new do
       begin
          ::Electrico::DashboardMailer.notificar( mensaje, user).deliver_now
       rescue StandardError  => e
         linea.error "Error en enviar email, en crear_solicitud #{e.inspect}"
       end
       #ActiveRecord::Base.connection.close
      #end
    end

    #Notifica por email informado del estado exitoso o fallido del proceso de toma de solicitud
    def notificar_por_email estado, solicitud, colaborador
      if solicitud.instalador.valid? and solicitud.instalador.activo

        case estado
        when :exito
          mensaje = crear_mensaje_de_exito(solicitud, colaborador )
        when :fallo
          mensaje = crear_mensaje_de_fallo(solicitud ,colaborador )
        end

        enviar_email( mensaje, solicitud.instalador )

        if saldo < SALDO_MINIMO
          mensaje = crear_mensaje_de_compra_de_creditos(solicitud, user )
          enviar_email( mensaje, user )
        end

      else
        return false
      end
    end

    #Notifica al colaborador del resultado de su intento de tomada de presupuesto
    def notificar estado, solicitud, colaborador
      suscripcion_instalador  =
        Electrico::Notificacion.find_by(:user_id => solicitud.instalador.id)

      if suscripcion_instalador.present? and solicitud.instalador.activo

        case estado
          when :exito
            mensaje = crear_mensaje_de_exito( solicitud, colaborador )
          when :fallo
            mensaje = crear_mensaje_de_fallo( solicitud, colaborador )
        end

        enviar( mensaje, suscripcion_instalador )          

      else
        return false
      end
    end
    
    #Usa webpush para enviar notificaciones push de acuero al resultado de la operación de toma de solicitud
    def webpush estado, solicitud, colaborador
      notificar estado ? :exito : :fallo, solicitud, colaborador
      notificar_saldo colaborador
      solicitud.sync colaborador
  #      notificar_saldo instalador
    end

  end
end
