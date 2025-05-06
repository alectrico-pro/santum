module Graph
  class Profile
    attr_accessor :name

    def initialize(name='')
      @name=name
    end

    def save!
    end

    def to_json(*a)
      data= { 'name' => @name }
      { 'json_class' => self.class.name,
            'data'   => data.to_json(*a)
      }
    end 

    def self.json_create(o)
      attrs=JSON.parse(o['data'], :quirks_mode => true )
      n=::Graph::Profile.new(attrs['name'])
    end

    def monito(wa_id=nil)
      " (profile (wa_id #{wa_id}) (name #{@name.parameterize}))"
    end

    def put
      " (profile (name #{@name.parameterize}))"
    end
  end
end
