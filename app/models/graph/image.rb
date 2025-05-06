module Graph
  class ::Graph::Image

    attr_accessor :caption
    attr_accessor :mime_type
    attr_accessor :sha256
    attr_accessor :id
    attr_accessor :link

    def initialize(caption='', mime_type='', sha256='', id='')
      @caption     = caption
      @mime_type   = mime_type
      @sha256      = sha256
      @id          = id
    end

    def procesa
      linea.info "En procesa de imagen"
      linea.info "No hacer nada"
    end

    def save!
    end

    def to_json(*a)
      data= {
              'caption'    => @caption,
              'mime_type'  => @mime_type,
              'sha256'     => @sha256,
              'id'         => @id
      }
      { 'json_class' => self.class.name,
            'data'   => data.to_json(*a)  }
    end 

    def self.json_create(o)

      attrs=JSON.parse(o['data'], :quirks_mode => true )

      n=::Graph::Image.new(
                             attrs['caption'],
                             attrs['mime_type'],
                             attrs['sha256'],
                             attrs['id']
      )
    end

    def put(msg_id=nil)
      fact_format = " (image ( caption #{@caption.blank? ? 'false' : @caption }) ( id #{@id.blank? ? 'false' : @id }) (mime_type #{@mime_type}) (sha256 #{@sha256}) "
      unless msg_id.nil?
        fact_format += "(msg_id #{msg_id}) "
      end
      if @link
         fact_format += "(link #{@link})"
      end
      fact_format += ' )'
    end

  end
end
