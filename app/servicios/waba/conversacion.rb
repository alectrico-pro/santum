class Waba::Conversacion
  extend Linea
  extend Encuentra
  include CrearUsuario

    def initialize( fact, publico=:cliente )
    fact       = fact
    nombre     = fact.object.entry.first.changes.first.value.contacts.first.profile.name

    begin
      mensajes = fact.object.entry.first.changes.first.value.messages
    rescue StandardError => e
      mensajes = fact.messages
    end

    if mensajes&.any?
      mensaje  = mensajes.first
      fono     = mensaje.from
      contexto = mensaje&.context

      case publico
      when :colaborador
        if not contexto
        #  linea.info "Público es colaboradores"
        #  linea.info "No tiene contexto, así que envíamos nuestra tarjeta de presentación"
        #  ::Waba::Transaccion.new(:colaborador).enviar_mensaje(fono, "Hola soy alec, el asistente eléctrico de alectrico®. Puede hacer preguntas libres o elegir opciones desde los menúes. Si se sabe los comandos rápidos también puede hacerlo. Normalmente es necesario estar entrenado para operar en la plataforma alectrico.cl pero los electricistas somos buenos aprendiendo de la forma que sea, así que adelante.")
        #  ::Waba::Transaccion.new(:colaborador).enviar_contacto_alec(fono)
        else
        #  ::Waba::Transaccion.new(:colaborador).set_read_to( contexto&.id )
        end
      when :cliente
        linea.info "Público es cliente"
        if not ( contexto.nil? || contexto.blank? )
          ::Waba::Transaccion.new(@publico).set_read_to( contexto&.id )
        end
      end
    end
    linea.info "Seteando los atributos"
    @fono        = fono
    @presupuesto = ::Electrico::Presupuesto.find_by(:fono => @fono)
    @presupuesto_electrico = ::Electrico::Presupuesto.find_by({:fono => @fono ,:es_electricidad => true})
   #@presupuesto_comercial = ::Electrico::Presupuesto.find_by({:fono => @fono ,:es_comercio     => true})

    @presupuesto_comercial = ::Encuentra.presupuesto( @fono )

    @nombre      = nombre
    @contexto    = contexto
    @mensaje     = mensaje
    @publico     = publico
  end


    #Siempre atiende en cubano si el fono es cubano
  def procesa
    @presupuesto = ::Electrico::Presupuesto.find_by(:fono => @fono)
    case @publico
    when :colaborador
   #  mensaje = "#{@nombre}, hemos detectado que está accesando el canal colaborador."
   #  ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)
      #
      if @fono.first == C.USA_CODE.to_s
      elsif @fono.first(2) == C.CUBA_CODE.to_s
        linea.info "Detectado un número de cuba, llamando a atender_cubano"
        atender_cubano
      elsif @fono.first(2) == C.CHILE_CODE.to_s
       @presupuesto.update(:es_comercio => false, :es_electricidad => true)
       atender_colaborador
      end
#     atender_colaborador
    when :cliente
      if @fono.first == C.USA_CODE.to_s
      elsif @fono.first(2) == C.CUBA_CODE.to_s
        linea.info "Detectado un número de cuba, llamando a atender_cubano"
        atender_cubano
      elsif @fono.first(2) == C.CHILE_CODE.to_s
        @presupuesto.update(:es_comercio => false, :es_electricidad => true)
        atender_cliente
      end
    end
  end

  #envía un link para resetear la pasword del usuario vigente en el canal whatsapp
  def procesar_reset( email )
    user = User.find_by(:email => email)
    raw, enc = Devise.token_generator.generate(User, :reset_password_token)
    user.update_columns(reset_password_token: enc, reset_password_sent_at: Time.current, confirmed_at: Time.current)
    #puts Rails.application.routes.url_helpers.edit_user_password_url(reset_password_token: raw, host: 'localhost:3000')

     mensaje = "#{@nombre}, debe pagar la visita siguiendo el link siguiente: #{@presupuesto.id}"
     ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)
     url = Rails.application.routes.url_helpers.edit_user_password_url(reset_password_token: raw, host: C.www_url)
     #rl ="#{C.api_url}/api/v1/electrico/presupuestos/#{@presupuesto.remember_token}/pagar_oferta/?auth_token=#{auth_token}"
     ::Waba::Transaccion.new(:cliente).enviar_url(@fono, url)

  end

  def atender_colaborador
   #mensaje = "#{@nombre}, estamos en atender colaborador."
   #::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)
    ::Waba::Transaccion.new(:colaborador).set_read_to( @contexto&.id ) if @contexto
    ::Waba::Transaccion.new(:colaborador).enviar_catalogo_maquetas(@fono)

    usuario = crear_editar_usuario
    crear_editar_presupuesto usuario
    identificar_comando
  end

  def atender_cubano
    linea.info "En atender cubano"
    #Atiende a un comprador potencial con fono cubano
    #Correspond enviar el catálogo de productos de cuba
    #En modo prueba solo enviaré un producto: una olla arrocera
    #Luego anotaré lo que escriba
    #Luego envíare el flow de reservar para cuba
    #De esta forma tendré los datos para la ficha de mensajería que pide el proveedor
    #y los datos del producto que tambén pide el proveedor
    #
    body = @mensaje.text.body
    comando=nil
    comando_match = body.match(/\/(.*)/)

    if not @presupuesto_comercial.present?
      mensaje = "#{@nombre}, no hemos encontrado un presupuesto, crearemos uno nuevo."
      ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)
       user = ::User.find_by(:fono => @fono)
       @presupuesto = ::Electrico::Presupuesto.create(
          {
            :instalador_id   => ::Instalador.first.id,
            :comuna          => "No ha ingresado municipio",
            :direccion       => "No ha ingresado dirección",
            :es_electricidad => false,
            :es_comercio     => true,
            :efimero         => true,
            :fono            => @fono
          }
       )
    end

    if body.length > 1 and Encuentra.presupuesto_comercial(  @fono )
      linea.info "Actualizando usuario y presupuesto comercial"
      usuario = crear_usuario( @fono, @nombre, "#{@fono}_cliente@alectrico.cl" )
      @presupuesto.update({:usuario => usuario,
                           :direccion => "No hay ingresado dirección",
                           :vigente => true,
                           :es_electricidad => false,
                           :es_comercio => true,
                           :descripcion => body.gsub("-"," ")})
      if es_la_primera_vez
        linea.info "Enviando say_datos_de_entrega"
        ::Waba::Transaccion.new(:cliente).say_datos_de_entrega( @fono, @presupuesto, "👋 #{@nombre}", "#{C.brand_cuba} aún no tiene almacenado los datos para hacerle llegar 🛺  productos, seleccione _Datos de Entrega_ para ingresarlos.", "Datos de Entrega")
        @presupuesto.update(:colaborador_id => nil, :mandato_aceptado => nil)
      
      else
        #no es la primera vez, entonces ya tiene sus datos en la plataforma
        #enviar reservar solo para que si quiere modificar los datos
        #luego enviar los catalogos
        enviar_catálogos
        ::Waba::Transaccion.new(:cliente).say_datos_de_entrega( @fono, @presupuesto, "👋 #{@nombre}", "#{C.brand_cuba} ya tiene almacenado los datos para hacerle llegar 🛺  productos, pero si necesita cambiarlos 📝, puede hacerlo al seleccionar _Datos de Entrega_.", "Datos de Entrega")
        @presupuesto.update(:colaborador_id => nil, :mandato_aceptado => nil)
      end

    end
  end
  
  def enviar_catálogos
    ::Waba::Transaccion.new(:cliente).enviar_catalogo_de_productos(@fono, :en_dolar)
    ::Waba::Transaccion.new(:cliente).enviar_catalogo_de_productos(@fono, :en_mlc)
    ::Waba::Transaccion.new(:cliente).enviar_catalogo_de_productos(@fono, :en_cup)
  end

  def es_la_primera_vez
     not ( @presupuesto.direccion or @presupuesto.orden or @presupuesto.usuario or @presupuesto.descripcion)
  end

  def atender_cliente

    # ::Waba::Transaccion.new(:cliente).say_flow_reservar( @fono, @nombre )

    #return

    body = @mensaje.text.body
    comando=nil
    comando_match = body.match(/\/(.*)/)

   #Este comando no se muestra 
    #Es temporal, simula un cubano 
    #en su whatsapp
    #Un cubano real será detectado por el código de Cuba
    cubano=nil
    cubano_match = body.match(/\/cubano(.*)/)
    unless cubano_match.nil?
      cubano = cubano_match[1]
      atender_cubano if cubano
      return
    end


    if body.length > 1 and @presupuesto and comando_match.nil?
     #::Waba::Transaccion.new(:cliente).llama_al_flow( @fono, 'gtin_visita')

      #eturn

      usuario = crear_usuario( @fono, @nombre, "#{@fono}_cliente@alectrico.cl" )
      @presupuesto.update({:usuario => usuario, 
                           :vigente => true,
                           :descripcion => body.gsub("-"," ")})
      if @presupuesto.usuario and @presupuesto.descripcion and @presupuesto.comuna
        ::Waba::Transaccion.new(:cliente).say_reservar( @fono, @presupuesto)
        @presupuesto.update(:colaborador_id => nil, :mandato_aceptado => nil)
        if @presupuesto and @presupuesto.usuario.present?
          @presupuesto.comunicar
        end

        mensaje = "#{@nombre}, estamos avisando a los colaboradores."
        ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)
        @presupuesto.bienvenido
        auth_token = ::Waba::Transaccion.new(:admin).autoriza( usuario)

        mensaje = "#{@nombre}, debe pagar la visita siguiendo el link siguiente: #{@presupuesto.id}"
        ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)
        url_de_pago="#{C.api_url}/api/v1/electrico/presupuestos/#{@presupuesto.remember_token}/pagar_oferta/?auth_token=#{auth_token}"
        ::Waba::Transaccion.new(:cliente).enviar_url(@fono, url_de_pago)
      end
      if @presupuesto.comuna.nil?
        mensaje = "Por favor ingrese la comuna donde nos necesita ( #{COMUNAS_PERMITIDAS} )."
        ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)
        ::Waba::Transaccion.new(@publico).say_comunas( @fono, @presupuesto.id )
      end
      if @presupuesto.direccion.nil?
        mensaje = "Por favor ingrese la direccion de esa forma: /direccion <<su direccion>>."
        ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)
      end

    else
    # ::Waba::Transaccion.new(:cliente).enviar_multi( @fono )
   #  mensaje = "#{@nombre}, estamos en atender cliente."
      ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)
      ::Waba::Transaccion.new(:cliente).set_read_to( @contexto&.id ) if @contexto
      #::Waba::Transaccion.new(:colaborador).enviar_catalogo_maquetas(@fono)

      usuario = crear_editar_usuario
      crear_editar_presupuesto usuario 
      identificar_comando
    end
  end


  def identificar_comando

#    mensaje = "#{@nombre}, estamos en identificar comando."
#    ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)

    body = @mensaje.text.body

    if body.match(/Diseña-una-instalación-eléctrica(.*)/)
      ::Waba::Transaccion.new(@publico).enviar_catalogo_maquetas(@fono)
    end


    #Este comando no se muestra
    #Es temporal, simula un cubano
    #en su whatsapp
    #Un cubano real será detectado por el código de Cuba
    cubano=nil
    cubano_match = body.match(/\/cubano(.*)/)
    unless cubano_match.nil?
      cubano = cubano_match[1]
      atender_cubano if cubano
      return
    end

    direccion=nil
    direccion_match = body.match(/\/direccion(.*)/)
    unless direccion_match.nil?
      direccion = direccion_match[1]
      procesar_direccion(direccion) if direccion
    end

    #Este comando no se muestra 
    email=nil
    reset_match = body.match(/\/reset(.*)/)
    unless reset_match.nil?
      email = reset_match[1]
      procesar_reset(email.gsub("-","")) if email
    end

    #Este comando no se muestra
    presupuesto_id=nil
    comunicar_match = body.match(/\/comunicar(.*)/)
    unless comunicar_match.nil?
      presupuesto_id = comunicar_match[1]
      presupuesto = ::Electrico::Presupuesto.find_by(:id => presupuesto_id.gsub("-",""))
      presupuesto.comunicar if presupuesto
    end


    email=nil
    email_match = body.match(/\/email-(.*)/)
    unless email_match.nil?
      email = email_match[1]
      procesar_email(email) if email
    end

    descripcion=nil
    descripcion_match = body.match(/\/descripcion(.*)/)
    unless descripcion_match.nil?
      descripcion = descripcion_match[1]
      procesar_descripcion(descripcion) if descripcion
    end

    unilineal=nil
    unilineal_match = body.match(/\/unilineal(.*)/)
    unless unilineal_match.nil?
      ::Waba::Transaccion.new(:colaborador).enviar_catalogo_maquetas(@fono) 
      mensaje = "#{@nombre}, hemos enviado el catálogo de electrodomésticos para que diseñe su instalación eléctrica."
      ::Waba::Transaccion.new(:colaborador).responder( @fono, @mensaje.id, mensaje)

    end

    presupuesto_match = body.match(/\/presupuesto(.*)/)
    unless presupuesto_match.nil? and @presupuesto
      ::Waba::Transaccion.new(@publico).edita_presupuesto(@presupuesto, @fono)
    end

    catalogo_match = body.match(/\/catalogo(.*)/)
    unless catalogo_match.nil? and @presupuesto
      ::Waba::Transaccion.new(:cliente).enviar_multi( @fono )
      mensaje = "#{@nombre}, hemos enviado el catálogo de servicios de alectrico ®, para que conozca nuestros servicios."
      ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)
    end

  end

  def procesar_descripcion descripcion
#    mensaje = "#{@nombre}, estamos en procesar descripcion. #{descripcion}"
 #   ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)
    @presupuesto.update(:descripcion => descripcion.gsub('-',' '))
    ::Waba::Transaccion.new(@publico).edita_presupuesto(@presupuesto, @fono)

  end

  def procesar_direccion direccion
   # mensaje = "#{@nombre}, estamos en procesar dirección. #{direccion}"
   # ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)
    @presupuesto.update(:direccion => direccion.gsub('-',' '))
    COMUNAS_PERMITIDAS.split(".").each do |comuna_permitida|
      comuna_match = direccion.downcase.match(comuna_permitida)
      unless comuna_match.nil?
        comuna = comuna_match[0]
        @presupuesto.update(:comuna => comuna)
        ::Waba::Transaccion.new(@publico).edita_presupuesto(@presupuesto, @fono)
        mensaje = "#{@nombre}, hemos actualizado la comuna: #{comuna}, revíselo ahora."
        ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)
        ::Waba::Transaccion.new(@publico).edita_presupuesto(@presupuesto, @fono)

      end
    end
    mensaje = "#{@nombre}, hemos actualizado la dirección: #{direccion}, revíselo ahora."
    ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)
    ::Waba::Transaccion.new(@publico).edita_presupuesto(@presupuesto, @fono)
    @presupuesto.difundir
  end

  def procesar_presupuesto
 #   mensaje = "#{@nombre}, estamos en procesar presupuesto #{@presupuesto.id}"
  #  ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)
    ::Waba::Transaccion.new(@publico).edita_presupuesto(@presupuesto, @fono)
  end

  def procesar_email email
  #  mensaje = "#{@nombre}, estamos en procesar email. #{email}"
  #  ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)
    email_match = email.match(/[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+/i)
    if email_match.nil?
      mensaje = "#{@nombre}, parece que Ud. no ha digitado correctamente su email, inténtelo nuevamente."
      ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)
    else
      @email = email_match[0]
       mensaje = "Crearemos un usuario para este email, fono y nombre #{@email} #{@fono} #{@nombre}."
      ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)
      usuario = crear_usuario( @fono, @nombre, @email )
      @presupuesto.update(:usuario => usuario) if @presupuesto
      mensaje = "Hemos asignado el presupuesto a este usuario, revíselo ahora."
      ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)
      ::Waba::Transaccion.new(@publico).edita_presupuesto(@presupuesto, @fono)
    end
  end

  def crear_editar_usuario
   # mensaje = "#{@nombre}, estamos en crear_editar_usuario."
   # ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)

    usuario = ::Gestion::Usuario.find_by(:fono => @fono)
    if not usuario.present?
      mensaje = "#{@nombre}, No hemos encontrado un usuario, digite /email con su email para poder crear un usuario."
      ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)
    end
  end

  def crear_editar_presupuesto usuario
    mensaje = "#{@nombre}, estamos en crear_editar presupuesto."
    ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)


    @presupuesto = ::Electrico::Presupuesto
           .no_pagado
           .efimero
           .no_realizado
           .vigente
           .find_by(:fono => @fono )

    if @presupuesto.es_electricidad
      mensaje = "#{@nombre}, estamos en crear_editar presupuesto es_electricidad."
     ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)

      if not @presupuesto.present? 
        mensaje = "#{@nombre}, no hemos encontrado un presupuesto, crearemos uno nuevo."
        ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)
         user = ::User.find_by(:fono => @fono)
         @presupuesto = ::Electrico::Presupuesto.create(
            {
              :instalador_id => ::Instalador.first.id,
              :comuna        => "Ingrese su comuna",
              :colaborador   => (@publico == :colaborador) ? user : nil,
              :descripcion   => "Ingrese la descripción del problema",
              :efimero       => true,
              :fono          => @fono,
              :direccion     => "Ingrese su dirección"
            }
         )
        mensaje = "#{@nombre}, hemos encontrado creado un presupuesto nuevo."
        ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)

        mensaje = "Por favor ingrese la comuna donde nos necesita ( #{COMUNAS_PERMITIDAS} )."
        ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)
        ::Waba::Transaccion.new(@publico).say_comunas( @fono, @presupuesto.id )
        mensaje = "#{@nombre}, por favor, edite los campos que se indican."
        ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)

        ::Waba::Transaccion.new(@publico).edita_presupuesto( @presupuesto, @fono)
        mensaje = "#{@nombre}, después de edición de presupuesto."
        ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)


      else
        if @presupuesto.usuario
          mensaje = "#{@nombre}, hemos encontrado un presupuesto."
          ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)
        else
          mensaje = "#{@nombre}, hemos encontrado un presupuesto sin usuario, ingrese /email <<su email>> para asignárselo a Ud."
          ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)
        end

      end

    elsif @presupuesto.es_comercio
     mensaje = "#{@nombre}, estamos en crear_editar presupuesto es_comercio ."
     ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)

    end
  end

  def procesa_version_1

    #necesito la comuna, el email y la descipcion
    #primer intento-a partir del body del mensaje que ya existe
    body = @mensaje.text.body
    tablero_match = body.match("Crea un tablero")
    unless tablero_match.nil?
      ::Waba::Transaccion.new(@publico).enviar_catalogo_maquetas(@fono)
      return
    end

    direccion=nil
    direccion_match = body.match(/\/d(.*)/)
    direccion = direccion_match[0]

    usuario = ::Gestion::Usuario.find_by(:fono => @fono)
    #email_match = body.match(/[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
    #usuario = ::Gestion::Usuario.find_by(:email => email_match[0]) unless email_match.nil?

  #esto es una trampa para crear usuario
    #si no se crea usuario no se puede crar el presupuesto
    #para crear usuario debe digitar el email
    #si el usuario ya existe con ese email genial

    linea.info "Body en procesa es:"
    linea.info body.inspect
    #Pasi 1, inscribir al usuario
    if not usuario.present?
      if body.nil?
        mensaje = "Por favor ingrese su email #{@email}."
        ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)
      else
        email_match = body.match(/[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+/i)
        linea.info email_match
        if email_match.nil?
          mensaje = "#{@nombre}, podría darnos una dirección de email desde donde pueda confirmar."
          ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)
        else
          @email = email_match[0]
          mensaje = "Por favor revise su correo en email #{@email}."
          ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)
          usuario = crear_usuario( @fono, @nombre, @email )
        end
      end
    end
    
    presupuesto = ::Electrico::Presupuesto
           .no_pagado
           .efimero
           .no_realizado
           .vigente
           .find_by(:fono => @fono )


    if not presupuesto.present? and body.length > 1
       presupuesto = ::Electrico::Presupuesto.create(
          {
            :instalador_id => ::Instalador.first.id,
            :comuna        => nil,
            :colaborador   => (@publico == :colaborador) ? usuario.user : nil,
            :usuario       => usuario,
            :descripcion   => body,
            :efimero       => true,
            :email         => usuario.email,
            :fono          => @fono,
            :name          => @nombre,
            :direccion     => direccion
          }
          )

       if @publico == :cliente
         mensaje = "Por favor ingrese la comuna donde nos necesita ( #{COMUNAS_PERMITIDAS} )."
         ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)
         ::Waba::Transaccion.new(@publico).say_comunas( @fono, presupuesto.id )
      else
         mensaje = "Por favor ingrese la comuna donde prefiere atender ( #{COMUNAS_PERMITIDAS} )."
         ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)
         ::Waba::Transaccion.new(@publico).say_comunas( @fono, presupuesto.id )
      end

    end

    #Paso 2 crear el presupuesto, ya que el usurio ya está y hay un body para extraer la comuna
    #Si es que existe
    if not presupuesto.present? and usuario.present? and not body.nil?  and body.match(VALID_COMUNA_REGEX)
      #Paso 2a. Se necesita la comuna y que esté dentro del área de cobertura de alectrico
      COMUNAS_PERMITIDAS.split(".").each do |comuna_permitida|
        #Encoding::CompatibilityError (incompatible encoding regexp match (ASCII-8BIT regexp with UTF-8 string)):
        #str_comuna_permitida = comuna_permitida.encode("utf-8", invalid: :replace, undef: :replace, replace: '?')
        comuna_match = body.downcase.match(comuna_permitida)
        if not comuna_match.nil?
          comuna = comuna_match[0]
          ::Waba::Transaccion.new(@publico).enviar_ubicacion( @fono, "Cobertura de alectrico ®" , "Puede incluir a #{comuna}")
          presupuesto = ::Electrico::Presupuesto.create(
          {
            :instalador_id => ::Instalador.first.id,
            :comuna        => comuna.capitalize,
            :usuario       => usuario,
            :colaborador   => (@publico == :colaborador) ? user : nil,
            :descripcion   => body,
            :efimero       => true,
            :email         => usuario.email,
            :fono          => @fono,
            :name          => @nombre,
            :direccion     => comuna.capitalize
           }
          )
          ::Waba::Transaccion.new(@publico).set_read_to( @mensaje.id )
          break
        end
      end
    end

    #permite actualizar el presupuesto reciente
    if presupuesto.present?

      #eliminando email
      body.gsub!(/[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]\w+/) {|s| ''}

      #eliminando comuna
      COMUNAS_PERMITIDAS.split(".").each do |comuna_permitida|
        comuna_match = body.match(comuna_permitida)
        unless comuna_match.nil?
          body.gsub!(comuna_permitida, "")
        end
      end

      #memeando con fuego
      if @publico == :cliente
        body.gsub!(/corte en/,"🔥 cortocircuito en")
      end

      #tratando de encontrar una descripion en el body limpiado de email y de comuna
      if @publico == :cliente
        if body.length > 1
          presupuesto.update(:descripcion => body )
          ::Waba::Transaccion.new(@publico).set_read_to( @mensaje.id )
          mensaje = "Fue guardada la Descripción como: #{body}"
          ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)

          mensaje = "Para informarnos del lugar de la visita, envíe la ubicación de un negocio cercano"
          ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)

          mensaje = "Puede subir imágenes o fotos técnicas. Agregue siempre un comentario. Ud. nos autoriza a divulgarlas a terceras personas (colaboradores autónomos) y declara que es el responsable por lo que pueda suceder a consecuencia de esa divulgación" 
          ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)

          mensaje = "Elija Visita a Domicilio de nuestro catálogo:"
          ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)

          ::Waba::Transaccion.new(@publico).enviar_multi( @fono )
          presupuesto.difundir




        else
          #si no se puede usar el body para crear una descripcion
          #solicitarle al usuario la descripcion
          mensaje = "#{@nombre}, cuénteme brevemente qué problema quiere que resolvamos en #{presupuesto.comuna}."
          ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)
        end     
      else
        if body.length > 1
          presupuesto.update(:descripcion => body )
          ::Waba::Transaccion.new(@publico).set_read_to( @mensaje.id )

          mensaje = "Para informarnos donde vive, envíe la ubicación de un negocio cercano a su residencia"
          ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)

          mensaje = "Puede subir imágenes o fotos técnicas para compartirlas con otras personas. Agregue siempre un comentario. Ud. nos autoriza a divulgarlas a terceras personas (colaboradores autónomos) y declara que es el responsable por lo que pueda suceder a consecuencia de esa divulgación"
          ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)

          mensaje = "Puede elegir electrodomésticos desde el catálogo, con ellos haremos un diagrama unilineal"
          ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)

          #::Waba::Transaccion.new(@publico).enviar_multi( @fono )

          #wip
          #LLlega bien al celular del destinatario pero el link
          #al catálogo no funciona y a veces muestra una pantalla
          #:Waba::Transaccion.new(:cliente).enviar_catalogo( @fono )
          
          ::Waba::Transaccion.new(@publico).enviar_catalogo_maquetas(@fono)

          #resupuesto.difundir #no se difunde
        else
          #si no se puede usar el body para crear una descripcion
          #solicitarle al usuario la descripcion
          mensaje = "#{@nombre}, cuénteme en qué lo podemos ayudar."
          ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)
        end
      end
    end

  end

  def lets_abord_original

    if @mensaje.nil?
      return false
    end

    #Cada cosa que escriba el usuario se va inscribiendo en un carrier y en
    #una llamada
    #Tal vez es reudnante, pero es algo que ayuda en la seguridad.
    #El carrier es una tabla muy simpole que junta el id de mensaje con el de presupuesto
    #Más adelante podría permitir fiscalizar cada llamada en un flujo con centro en cada
    #presupuesto
    #aborta las repeticiones
    carrier = ::Electrico::Carrier.find_by(:nombre => @mensaje.id)
    if carrier.present?
      return
    end

    #Cualquier presupuesto util para usuarios y colaboradores será usado para atender al usuaerio
    #en su aboradje vía whatsapp.
    #Util para un colaborador es que no haya sigo pagado
    #Util para el usuario es que no haya sido realizado
    #materia del Instalado es un presupuesto que siga vigente
    #esto es, que el haya decido o cerrarlo
    #En las primeras interesacciones solo se usará un presupuesto efímero sin usuario que
    #sea descartable con e fin inical de mantener el flujo de conversación con el usuario
    #Por ejemplo, evita tener que enviar dos veces el catálogo.
    ##Cualdquier modificacion'de este presupuesto de tracking loa hará desaparecer de aquí
    #Con lo que será creado un nuevo presupuesto para el mismo usuario
    #
    presupuesto = ::Electrico::Presupuesto.no_pagado.efimero.no_realizado.vigente.find_by(:fono => @mensaje.from )

    #Crear el presupuesto
    if presupuesto.present?
      ::Waba::Transaccion.new(@publico).set_read_to( @mensaje.id )
    else
      ::Waba::Transaccion.new(@publico).set_delivered_to( @mensaje.id ) 

      presupuesto = ::Electrico::Presupuesto.new(
        { 
        :instalador_id => ::Instalador.first.id,
        :efimero       => true,
        :fono          => @fono,
        :name          => @nombre
        }
      )


      if presupuesto.save(context: :acceso_whatsapp)
        #Anota los id de mensajes para combatir ataques de replay
        carrier = ::Electrico::Carrier.create(  :nombre => @mensaje.id,
                                                :tarifa => presupuesto.id)

        comuna = 'Providencia'
        direccion = 'Providencia'
        mensaje = "Hola #{@nombre}, como empresa y además como comunidad trabajamos mayormente en Providencia."
        ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)
        ::Waba::Transaccion.new(@publico).enviar_ubicacion( @fono, 'Providencia', 'Providencia')
      else
        ::Waba::Transaccion.new(@publico).say_bah( @fono )
      end
    end


    body = @mensaje.text.body

    email_match = body.match(/[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)

    COMUNAS_PERMITIDAS.split(".").each do |comuna_permitida|
      comuna_match = body.match(comuna_permitida)
      unless comuna_match.nil?
        mensaje  = "Comuna encontrada es #{comuna_match}"
        comuna = comuna_match
        ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)
        break
      end    
    end

    #completar datos
    if presupuesto.comuna.nil? 
      if comuna.nil?
        mensaje = "Por favor escriba en qué comuna necesita servicios."
        ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje) 
      else
        presupuesto.update(:comuna => comuna[0])
      end
    end

    if presupuesto.descripcion.nil? or presupuesto.descripcion.blank?
      mensaje = "#{@nombre}, cuénteme brevemente qué problema quiere que resolvamos en alectrico®."
      ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)
      presupuesto.update(:descripcion => body)
    end

    if presupuesto.email.nil? 
      if email_match.nil?
        mensaje = "#{@nombre}, si no le importa mucho, podría darnos una dirección de email como una alternativa de comunicación."
        ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)
      else
        @email = email_match[0]
        mensaje = "Fue encontrado email #{@email}."
        ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)
        usuario = crear_usuario( @fono, @nombre, @email )

        presupuesto.update(:email => @email)
      end
    end

    if presupuesto.email.nil? or presupuesto.comuna.nil? or presupuesto.descripcion.nil? or presupuesto.descripcion.blank?
     #mensaje = "Creo que es mejor que envie todas sus respuestas en un solo mensaje. Ya puede comenzar a responder."
     #::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)
    #else

     # mensaje = "Antes de presupuesto.update usuario"
      #::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)

      #limpiando la descripcion
      descripcion = presupuesto.descripcion
      descripcion.gsub!(/[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]\w+/) {|s| ''}  

      COMUNAS_PERMITIDAS.split(".").each do |comuna_permitida|
        comuna_match = body.match(comuna_permitida)
       # mensaje = "comuna_match: #{comuna_match}"
       # ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)

        unless comuna_match.nil?
          descripcion.gsub!(comuna_permitida, "")
        end
      end
      descripcion.gsub!(/corte/,"🔥 cortocircuito")

      mensaje = "Fue guardada la Descripción como: #{descripcion}"
      ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)


     if presupuesto.email.nil?
      if email_match.nil?
        mensaje = "#{@nombre}, si no le importa mucho, podría darnos una dirección de email como una alternativa de comunicación."
        ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)
      else
        @email = email_match[0]
        mensaje = "Fue encontrado email #{@email}."
        ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)
        usuario = crear_usuario( @fono, @nombre, @email )
        presupuesto.update(:email => @email)
      end
    end

      presupuesto.update(:usuario => usuario,
                         :descripcion => descripcion )

     # mensaje = "Presupuesto con usuario es #{presupuesto.inspect}"
     # ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)

      mensaje = "Felicitaciones, ya ingresó los datos. Tal vez sea buen momento de revisar nuestro catálogo:"
      ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)
      ::Waba::Transaccion.new(@publico).enviar_multi( @fono )
     # mensaje = "Le hemos envíado un correo con un link de confirmación, es importante que siga ese link que lo llevará a la plataforma de alectrico®"
     # ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)
      presupuesto.difundir
    end
  end


    #Las llamadas anotan llamads a este presupeusto, a diferencia de los carriers
    #Estos datos desapreceran cuando el presupuesto sean elminado
    #También se asocia al carrier
    #Así es que un presupuesto podría ser abordado por diferentes usuarios
    #Eso no tiene sentido ahora pero podría revelar un hackeo,
    #A estas alturas tengo que tener la vista puesta en esos detalles
  # if presupuesto
  #   llamada =  presupuesto.llamadas.create(
  #             :minutos        => 0,
  #             :costo          => 0,
   #            :contenido      => @mensaje&.id,
  #             :carrier_id     => carrier.id,
  #             :fono           => @fono
  #   )
  # end

  #nd


  def crear_usuario fono, nombre, email

    mensaje = "En crear_usuario #{email.inspect}"
    #::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)

    usuario = Gestion::Usuario.find_or_create_by(:email => email ) do |u|
      u.nombre = nombre
      u.fono  =  fono
    end

    #mensaje = "Usuario es. #{usuario.inspect}"
    #::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)

    if usuario
      usuario.valid?
      user = usuario.create_user
      if user.valid?
        mensaje = "Qué bueno! Su usuario ha sido creado y desde ahora podrá iniciar sesión en #{C.designer_url} con su email y fono. Use fono como contraseña y email como usuario. Puede cambiar su contraseña en #{C.domain}."
        ::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, mensaje)
      end
    end

    user = User.find_or_create_by( :email => usuario.email) do |u|
      u.name     = usuario.nombre
      u.email    = usuario.email
      u.fono     = usuario.fono
      u.password = usuario.fono
    end

    user.send_confirmation_instructions

    mensaje = "user.id  #{user.id}"
    #::Waba::Transaccion.new(@publico).responder( @fono, @mensaje.id, user.id)

    return usuario

  end

  def crear_presupuesto nombre, fono

    usuario = Gestion::Usuario.find_or_create_by(
      :email => "#{nombre}_#{fono}@alectrico.cl" ) do |u|
      u.nombre = nombre
      u.fono  =  fono
    end

    if usuario
      usuario.valid?
      logger.info "Errores de usuario #{usuario.errors.messages}"
      logger.info "Usuario id es #{usuario.id}"
      logger.info "Usuario es #{usuario.inspect}"
      user = usuario.create_user
    end

    user = User.find_or_create_by( :email => usuario.email) do |u|
      u.name     = usuario.nombre
      u.email    = usuario.email
      u.fono     = usuario.fono
      u.password = usuario.fono
    end

    usuario.update(:user_id => user.id)

    presupuesto = ::Electrico::Presupuesto.new(
      { :usuario_id    => usuario.id,
        :instalador_id => ::Instalador.first.id,
        :efimero       => true,
        :colaborador   => (@publico == :colaborador) ? user : nil,
        :comuna        => 'Providencia',
        :fono          => usuario.fono,
        :email         => usuario.email,
        :name          => nombre}
      )

    presupuesto.valid?(context: :acceso_whatsapp)
    logger.info "#{presupuesto.errors.messages}"
    presupuesto.save

    if presupuesto.save!(context: :acceso_whatsapp)
      return presupuesto
    else
      linea.error "Error salvando presupuesto en acceso_whatsapp #{presupuesto.errors.inspect}"
      return false
    end

  end

end
