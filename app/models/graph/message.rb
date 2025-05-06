module Graph
  class Message
    #En vez de context, debiese haber sido contexts
    #Pues se expresa como un arreglo de varios context
    #Lo mismo pasa con entry en el objeto 'object'
    #Debiese haber sido entries
    attr_accessor :context 
    attr_accessor :from
    attr_accessor :id
    attr_accessor :timestamp
    attr_accessor :text
    attr_accessor :errors
    attr_accessor :type
    attr_accessor :button
    attr_accessor :document
    attr_accessor :contacts
    attr_accessor :image
    attr_accessor :video
    attr_accessor :order
    attr_accessor :location
    attr_accessor :interactive
    attr_accessor :reaction

    attr_accessor :mensaje

    def initialize(context='', from='', id='wamid.ID', timestamp='', text=nil, errors=[], type='text', button=nil, document=nil, contacts=[], image='', video='', order=nil, location=nil, interactive=nil, reaction=nil)
      @context     = context
      @from        = from
      @id          = id
      @timestamp   = timestamp
      @text        = text
      @errors      = errors
      @type        = type
      @button      = button
      @document    = document
      @contacts    = contacts
      @image       = image
      @video       = video
      @order       = order
      @location    = location
      @interactive = interactive
      @reaction    = reaction

      #esto se usa en los descendientes para referirse a este mensaje
      @@mensaje   = self

    end

    def mensaje
      @@mensaje
    end

    def procesa( fono, mensaje_id, publico)
      linea.info "En procesa de message"
      if @button and @button.respond_to?(:procesa)

        #linea.info @button.inspect
        @button.procesa(fono, mensaje_id, publico) #nless @button.empty?
        #si button es '' entonces llama erroneamente a procesa_autorizado en 
        #Esto solo se pudo ver en las pruebas
        #Pero ya lo solucioné, solo se ingresa nil desde mensaje
        #nunca ''
      end
      if @interactive
        @interactive&.procesa( fono, mensaje_id, publico)
      end
     # @document&.procesa
     # @contacts&.procesa
     # @image&.procesa
     # @order&.procesa
     # @location&.procesa
    end

    def save!
    end

    def to_json(*a)
      data= {
              'context'     => @context,
              'from'        => @from,
              'id'          => @id,
              'timestamp'   => @timestamp,
              'text'        => @text,
              'errors'      => @errors,
              'type'        => @type,
              'button'      => @button,
              'document'    => @document,
              'contacts'    => @contacts,
              'image'       => @image,
              'video'       => @video,
              'order'       => @order,
              'location'    => @location,
              'interactive' => @interactive,
              'reaction'    => @reaction
      }

      { 'json_class' => self.class.name,
            'data'   => data.to_json(*a)  }
    end 

    def self.json_create(o)

      attrs=JSON.parse(o['data'], :quirks_mode => true )

      unless attrs['button'].nil?
        button_json = {"json_class" => "Graph::Button",
                        'data'       => attrs['button'].to_json}
        button = ::Graph::Button.json_create(button_json)
      end

      unless attrs['document'].nil?
        document_json = {"json_class" => "Graph::Document",
                        'data'       => attrs['document'].to_json}
        document = ::Graph::Document.json_create(document_json)
      end

      unless attrs['context'].nil?
        context_json = {"json_class" => "Graph::Context", 
                        'data'       => attrs['context'].to_json}
        context = ::Graph::Context.json_create(context_json)
      end

      errors = attrs['errors']
      errors_list = []
      if  errors&.any?
        errors.each do |error_data|
          error_json = { 'data' => error_data.to_json }
          error = ::Graph::Error.json_create( error_json )
          errors_list << error
        end
      end

      unless attrs['text'].nil?
       text_json = {"json_class"=>"Graph::Text", 'data' => attrs['text'].to_json}
       text = ::Graph::Text.json_create(text_json)
      end

      contacts = attrs['contacts']
      contacts_list = []
      if contacts&.any?
        contacts.each do |contact_data|
          contact_json = {'data' => contact_data.to_json}
          contact = ::Graph::Contact.json_create(contact_json)
          contacts_list << contact
        end
      end

      unless attrs['image'].nil?
        image_json = {"json_class"=>"Graph::Image", 'data' => attrs['image'].to_json}
        image = ::Graph::Image.json_create(image_json)
      end

      unless attrs['video'].nil?
        video_json = {"json_class"=>"Graph::Video",
                      'data' => attrs['video'].to_json}
        video = ::Graph::Video.json_create(video_json)
      end

      unless attrs['order'].nil?
        order_json = {"json_class"=>"Graph::Order", 'data' => attrs['order'].to_json}
        order = ::Graph::Order.json_create(order_json)
      end

      unless attrs['location'].nil?
        location_json = {"json_class" => "Graph::Location",
                        'data'       => attrs['location'].to_json}
        location = ::Graph::Location.json_create(location_json)
      end

      unless attrs['interactive'].nil?
        interactive_json = {"json_class" => "Graph::Interactive",
                        'data'       => attrs['interactive'].to_json}
        interactive = ::Graph::Interactive.json_create(interactive_json)
      end

      unless attrs['reaction'].nil?
        reaction_json = {"json_class" => "Graph::Reaction",
                        'data'       => attrs['reaction'].to_json}
        reaction = ::Graph::Reaction.json_create(reaction_json)
      end


      n=::Graph::Message.new(
                             context,
                             attrs['from'],
                             attrs['id'],
                             attrs['timestamp'],
                             text,
                             errors_list,
                             attrs['type'],
                             button,
                             document,
                             contacts_list,
                             image,
                             video,
                             order,
                             location,
                             interactive,
                             reaction
      )


    end

    def monito(file_handler=nil, entry_id=nil)

      raise "file_handler nil en message monito" if file_handler.nil?
      #raise "entry_id es nil en message monito" if entry_id.nil?

      message = " (message (from #{@from}) (entry_id #{entry_id}) (id #{@id}) (timestamp #{@timestamp}) (type #{@type})) "

      if ENV["REDIS_URL"].present?
        Redisfile.new.set('objeto', message )
        Redisfile.new.set('objeto', @order&.send(:puts,file_handler,@id))

        Redisfile.new.set('objeto', @location&.send(:monito,@id))
        Redisfile.new.set('objeto', @reaction&.send(:put,@id))
        Redisfile.new.set('objeto', @document&.send(:put,@id))
        Redisfile.new.set('objeto', @text&.send(:put,@id))
        Redisfile.new.set('objeto', @image&.send(:put,@id))
        Redisfile.new.set('objeto', @video&.send(:put,@id))

        redisfile = Redisfile.new

        Redisfile.new.set('objeto', @order&.send(:puts,        redisfile, @id))
        Redisfile.new.set('objeto', @interactive&.send(:monito,redisfile, @id))
        Redisfile.new.set('objeto', @context&.send(:monito,    redisfile, @id))
        Redisfile.new.set('objeto', @button&.send(:monito,     redisfile, @id))

      end

      file_handler.puts message

      file_handler.puts @order&.send(:puts,file_handler,@id)
      file_handler.puts @location&.send(:monito,@id)
      file_handler.puts @interactive&.send(:monito,file_handler, @id)
      file_handler.puts @reaction&.send(:put,@id)
      file_handler.puts @document&.send(:put,@id)
      file_handler.puts @context&.send(:monito,file_handler, @id)
      file_handler.puts @text&.send(:put,@id)
      file_handler.puts @image&.send(:put,@id)
      file_handler.puts @video&.send(:put,@id)
      file_handler.puts @button&.send(:monito, file_handler, @id)
      @errors.each do |i|
        file_handler.puts i&.send(:monito, file_handler, @id)
      end

    end

    def put
      fact_format = " (message (from #{@from}) (id #{@id}) (timestamp #{@timestamp}) (type #{@type})  "
   
      @errors.each do |i|
        contenido = i&.send(:put, @id)
        unless contenido.blank?
          fact_format += contenido
        end
      end

      @contacts.each do |i|
        contenido = i&.send(:put)
        unless contenido.blank?
          fact_format += contenido
        end
      end

      contenido =  @order&.send(:put)
      unless contenido.blank?
        fact_format += contenido
      end

      contenido =  @location&.send(:put)
      unless contenido.blank?
        fact_format += contenido
      end

      raise "@id es nil en message" if @id.nil?

      contenido =  @interactive&.send(:put, @id)
      unless contenido.blank?
        fact_format += contenido
      end

      contenido =  @reaction&.send(:put)
      unless contenido.blank?
        fact_format += contenido
      end

      contenido =  @document&.send(:put, @id)
      unless contenido.blank?
        fact_format += contenido
      end

      contenido =  @context&.send(:put)
      unless contenido.blank?
        fact_format += contenido
      end

      contenido =  @text&.send(:put)
      unless contenido.blank?
        fact_format += contenido
      end

      contenido =  @image&.send(:put)
      unless contenido.blank?
        fact_format += contenido
      end

      contenido =  @video&.send(:put)
      unless contenido.blank?
        fact_format += contenido
      end

      contenido = @button&.send(:put)
      unless contenido.blank?
        fact_format += contenido
      end

      fact_format += ' )'
    end


  end
end
