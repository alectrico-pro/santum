module Graph
  class Document
    attr_accessor :caption
    attr_accessor :filename
    attr_accessor :mime_type
    attr_accessor :sha256
    attr_accessor :id

    def initialize(caption='', filename='', mime_type='', sha256='', id='')
      @caption   = caption
      @filename  = filename
      @mime_type = mime_type
      @sha256   = sha256
      @id        = id
    end

    def save!
    end

    def to_json(*a)
      data = {
        'caption'   => @caption,
        'filename'  => @filename,
        'mime_type' => @mime_type,
        'sha256'   => @sha256,
        'id'        => @id     
      }
      { 'json_class' => self.class.name,
        'data' => data.to_json(*a) }
    end
    
    def self.json_create(o)
      attrs = JSON.parse(o['data'], :quirks_mode => true )
      n = ::Graph::Document.new(
        attrs['caption'],
        attrs['filename'],
        attrs['mime_type'],
        attrs['sha256'],
        attrs['id']   )
    end

    def put(msg_id=nil)
      raise "msg_id is nil on Graph::Document" if msg_id.nil?
      fact_format = ' ( document '
      fact_format += "(caption #{@caption}) (msg_id #{msg_id}) (filename #{@filename}) (mime_type #{@mime_type}) (sha256 #{@sha256}) (id #{@id} )"
      fact_format += ' )'
    end

  end
end
