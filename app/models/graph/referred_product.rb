module Graph
  class ReferredProduct
    attr_accessor :catalog_id
    attr_accessor :product_retailer_id

    def initialize(catalog_id='', product_retailer_id='')
      @catalog_id          = catalog_id
      @product_retailer_id = product_retailer_id
    end

    def save!
    end

    def to_json(*a)
      data = { 'catalog_id'          => @catalog_id,
               'product_retailer_id' => @product_retailer_id }
      { 'json_class' => self.class.name,
        'data' => data.to_json(*a) }
    end
    
    def self.json_create(o)
      attrs = JSON.parse(o['data'], :quirks_mode => true )
      catalog_id          = attrs['catalog_id']
      product_retailer_id = attrs['product_retailer_id']
      n = ::Graph::ReferredProduct.new(catalog_id, product_retailer_id)
    end

    def put(context_id=nil)
      raise "context_id es nil" if context_id.nil?
      " (referred_product (context_id #{context_id}) (catalog_id #{@catalog_id}) (product_retailer_id #{@product_retailer_id})  )"
    end

  end
end
