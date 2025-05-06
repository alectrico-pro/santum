module Graph
  class Error
    attr_accessor :code
    attr_accessor :details
    attr_accessor :title
    attr_accessor :message 
    attr_accessor :error_subcode
    attr_accessor :type

    def initialize(code='', details='', title='', message='', error_subcode='',type='')
      @code          = code
      @details       = details
      @title         = title
      @message       = message
      @error_subcode = error_subcode
      @type          = type
    end

    def save!
    end

    def to_json(*a)
      data= { 'code'          => @code,
              'details'       => @details,
              'title'         => @title,
              'message'       => @message,
              'error_subcode' => @error_subcode,
              'type'          => @type
      }
      { 'json_class' => self.class.name,
            'data'   => data.to_json(*a)  }
    end 

    def self.json_create(o)
      attrs=JSON.parse(o['data'], :quirks_mode => true )
      n=::Graph::Error.new(attrs['code'],
                           attrs['details'],
                           attrs['title'],
                           attrs['message'],
                           attrs['error_subcode'],
                           attrs['type']
                          )


    end

    def monito( file_handler=nil, father_id=nil)
      raise "file_handler is nil con Graph::Error" if file_handler.nil?
      raise "father_id is nil on Graph::Error" if father_id.nil?


      fact_format =  " (error (title #{@title.parameterize}) (code #{@code}) "
      fact_format += "(father_id #{father_id}) "

      if @details
        fact_format += "(details #{@details.parameterize}) "
      end
      if @message
        fact_format += "( message #{@message.parameterize}) "
      end
      if @error_subcode
        fact_format += "(error_subcode #{@error_subcode}) "
      end
      if @type
        fact_format += "(type #{@type})"
      end
      fact_format += " )"

      file_handler.puts fact_format
    end

    def put( father_id=nil)

      raise "father_id is nil" if father_id.nil?

      fact_format =  " (error (title #{@title.parameterize}) (code #{@code}) "
      fact_format += " (father_id #{father_id}) "
      if @details
        fact_format += " (details #{@details.parameterize}) "
      end
      if @message
        fact_format += " (message #{@message.parameterize}) "
      end
      if @error_subcode
        fact_format += " (error_subcode #{@error_subcode}) "
      end
      if @type
        fact_format += " (type #{@type})"
      end
      fact_format += " )"

    end

  end
end
