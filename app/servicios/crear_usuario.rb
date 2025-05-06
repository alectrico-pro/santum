module CrearUsuario

    def crear_usuario fono, nombre, email

    mensaje = "En crear_usuario #{email.inspect}"
    #::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)

    usuario = Gestion::Usuario.find_or_create_by(:email => email ) do |u|
      u.nombre = nombre
      u.fono  =  fono
    end

    #mensaje = "Usuario es. #{usuario.inspect}"
    #::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)

    #if usuario
    #  usuario.valid?
    #  user = usuario.create_user
    #  if user.valid?
    #    mensaje = "Qué bueno! Su usuario ha sido creado y desde ahora podrá iniciar sesión en #{C.designer_url} con su email y fono. Use fono como contraseña y email como usuario. Puede cambiar su contraseña en #{C.domain}."
    #    ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)
    #  end
    #end

    user = User.find_or_create_by( :email => usuario.email) do |u|
      u.name     = usuario.nombre
      u.email    = usuario.email
      u.fono     = usuario.fono
      u.password = usuario.fono
    end

    user.send_confirmation_instructions

    usuario.update(:user_id => user.id)

    mensaje = "user.id  #{user.id}"
    #::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, user.id)

    return usuario

  end
end
