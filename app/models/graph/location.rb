module Graph
  class Location
    attr_accessor :name
    attr_accessor :address
    attr_accessor :latitude
    attr_accessor :longitude
    attr_accessor :url

    def initialize(name='', address='', latitude='', longitude='', url='')
      @name      = name
      @address   = address
      @latitude  = latitude
      @longitude = longitude
      @url       = url
    end

    def procesa
      linea.info "En procesa de location"
      linea.info "No hacer nada todavía"
    end

    def save!
    end

    def to_json(*a)
      data= {
              'name'      => @name,
              'address'   => @address,
              'latitude'  => @latitude,
              'longitude' => @longitude,
              'url'       => @url
      }
      { 'json_class' => self.class.name,
            'data'   => data.to_json(*a)  }
    end 

    def self.json_create(o)

      attrs=JSON.parse(o['data'], :quirks_mode => true )

      n=::Graph::Location.new(
                             attrs['name'],
                             attrs['address'],
                             attrs['latitude'],
                             attrs['longitude'],
                             attrs['url']
      )
    end

    def monito(msg_id=nil)
      raise "msg_id nil en location" if msg_id.nil?
      fact_format = " (location "
      fact_format +=  "(msg_id #{msg_id})"
      unless @name.blank?
        fact_format +=  "(name #{@name.parameterize})"
      end
      unless @address.blank?
        fact_format += "(address #{@address.parameterize})"
      end
      unless @latitude.blank?
        fact_format += "(latitude #{@latitude})"
      end
      unless @longitude.blank?
        fact_format += "(longitude #{@longitude})"
      end
      unless @url.blank?
        fact_format += "(url #{@url})"
      end
      fact_format += " )"
    end

    def put(msg_id=nil)
      fact_format = " (location "
            unless msg_id.nil?
        fact_format += "(msg_id #{msg_id}) "
      end
      unless @name.blank?
        fact_format +=  "(name #{@name.parameterize})"
      end
      unless @address.blank?
        fact_format += "(address #{@address.parameterize})"
      end
      unless @latitude.blank?
        fact_format += "(latitude #{@latitude})"
      end
      unless @longitude.blank?
        fact_format += "(longitude #{@longitude})"
      end
      unless @url.blank?
        fact_format += "(url #{@url})"
      end
      fact_format += " )"
    end

  end
end
