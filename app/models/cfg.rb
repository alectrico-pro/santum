#Esta clase sirve para llamar a los atributos del archivo de configuración de la forma C.atributo.
#El archivo de configuración se encuentra en config/cfg.yml y se adapta a los diferentes ambientes de Rails.env
class Cfg
  def initialize(archivo='cfg.yml',selector=Rails.env)
    @cfg = YAML::load(ERB.new(File.read(Rails.root.join("config",archivo))).result)[selector]
    begin
      @cfg.each do |c|
        self.class.send(:define_method, c[0]) do
          c[1]          
        end
      end
    rescue
      raise "Error buscando la configuración en #{archivo} para #{selector}"
    end
  end
  def method_missing(method, *arg)
    if @cfg.key?(method.to_s) 
      return @cfg[method.to_s]
    end
  end

  def method_missing method, *args, &block
    #return super method, *args, &block unless method.to_s =~ /^coding_\w+/
    self.class.send(:define_method, method) do
      raise "Error: Debe crear método para: " + method.to_s.gsub(/^coding_/, '').to_s
    end
    self.send method, *args, &block
  end



  def respond_to_missing?(method, *)
      if @cfg.key?(method.to_s)
      return true
    end
  end
  def ok?
    @cfg.key?('ok') 
  end
end
