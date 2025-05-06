module Graph
  class Pricing
    attr_accessor :billable
    attr_accessor :pricing_model
    attr_accessor :category

    def initialize(billable='', pricing_model='', category='')
      @billable      = billable
      @pricing_model = pricing_model
      @category      = category
    end

    def save!
    end

    def to_json(*a)
      data= {'billable'      => @billable,
             'pricing_model' => @pricing_model,
             'category'      => @category }
      { 'json_class' => self.class.name,
            'data'   => data.to_json(*a)  }
    end 

    def self.json_create(o)
      attrs=JSON.parse(o['data'], :quirks_mode => true )
      n=::Graph::Pricing.new(attrs['billable'], attrs['pricing_model'], attrs['category'])
    end

    def monito( status_id=nil)
      raise "Status_id is nil on monito de pricing" if status_id.nil?
      fact_format = " (pricing (billable #{@billable}) (category #{@category}) "
      unless @pricing_model.blank?
        fact_format += "(pricing_model #{@pricing_model}) (status_id #{status_id})  "
      end
      fact_format += " )"
    end


    def put
      fact_format = " (pricing (billable #{@billable}) (category #{@category}) "
      unless @pricing_model.blank?
        fact_format += "(pricing_model #{@pricing_model})"
      end
      fact_format += " )"
    end
  end
end
