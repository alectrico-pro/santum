module Graph
  class Video

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
      linea.info "En procesa de video"
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

      n=::Graph::Video.new(
                             attrs['caption'],
                             attrs['mime_type'],
                             attrs['sha256'],
                             attrs['id']
      )
    end

    def put(msg_id=nil)
      fact_format = ' (video '
      unless msg_id.nil?
        fact_format += "(msg_id #{msg_id}) "
      end
      fact_format += " ( caption #{@caption.blank? ? 'false' : @caption }) ( id #{@id.blank? ? 'false' : @id }) "
      fact_format += ' )'
    end

  end
end
