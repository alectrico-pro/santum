module Graph
  class Contact

    attr_accessor :wa_id
    attr_accessor :profile
    attr_accessor :name
    attr_accessor :org
    attr_accessor :phones
    attr_accessor :input

    def initialize(profile='', wa_id='', name=nil, org=nil, phones=[], input='' )
      @profile = profile
      @wa_id   = wa_id
      @name    = name
      @org     = org
      @phones  = phones
      @input   = input
    end

    def save!
    end

    def to_json(*a)
      data= {'profile' => @profile ,
               'wa_id' => @wa_id,
               'name'  => @name,
               'org'   => @org,
              'phones' => @phones,
              'input'  => @input }

      {   'json_class' => self.class.name,
              'data'   => data.to_json(*a)  }
    end 

    def self.json_create(o)
      attrs=JSON.parse(o['data'], :quirks_mode => true )

      unless attrs['profile'].nil?
        profile_json = {"json_class"=>"Graph::Profile",
                        'data' => attrs['profile'].to_json}
        profile = ::Graph::Profile.json_create(profile_json)
      end

      unless attrs['name'].nil?
        name_json = {"json_class" => "Graph::Name",
                     'data' => attrs['name'].to_json}
        name = ::Graph::Name.json_create(name_json)
      end

      unless attrs['org'].nil?
        org_json = {"json_class" => "Graph::Org",
                    'data' => attrs['org'].to_json }
        org  = ::Graph::Org.json_create(org_json)
      end
      
      phones = attrs['phones']
      phones_list = []   
      if phones&.any?
        phones.each do |phone_data|
          phone_json ={ 'json_class' => 'Graph::Phone',
                      'data' =>  phone_data.to_json }
          phone = ::Graph::Phone.json_create( phone_json )
          phones_list << phone
        end
      end

      ::Graph::Contact.new(
        profile,
        attrs['wa_id'],
        name,
        org,
        phones_list,
        attrs['input']  )
    end

    def monito(file_handler=nil, entry_id=nil)

      fact_format = " (contact (wa_id #{@wa_id}) "
      unless entry_id.nil?
        fact_format += "(entry_id #{entry_id}) "
      end

     @phones.each do |i|
       file_handler.puts = i&.send(:monito, @wa_id)
     end


      file_handler.puts @org&.send(:monito, @wa_id)

      unless @input.blank?
        fact_format += " (input #{@input}))"
      end

      contenido = @name&.send(:put)
      unless contenido.blank?
        fact_format += contenido
      end

      file_handler.puts @profile&.send(:monito, @wa_id)

      fact_format += " )"
      file_handler.puts fact_format
    end


    def put(message_id=nil)
      fact_format = " (contact (wa_id #{@wa_id}) "
      unless message_id.nil?
        fact_format += "(message_id #{message_id}) "
      end

      @phones.each do |i|
        contenido = i&.send(:put)
        unless contenido.blank?
          fact_format += contenido
        end
      end

      contenido = @org&.send(:put)
      unless contenido.blank?
        fact_format += contenido
      end

      unless @input.blank?
        fact_format += " (input #{@input}))"
      end

      contenido = @name&.send(:put)
      unless contenido.blank?
        fact_format += contenido 
      end

      contenido = @profile&.send(:put)
      unless contenido.blank?
        fact_format += contenido 
      end
      fact_format += " )"
    end

  end
end
