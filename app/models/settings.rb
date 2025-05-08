#https://rubyhero.dev/environment-variables
#las variables env pueden cambiar y no necesitas hacer
#nuevamente deploy
#wip
#Modelo tld.rb
#Usa Setting.tld para cambiar entre configuraciones
#disponibles en el archivo tld.yml en config
class Settings
 class << self
   def env_selector
     ENV['ENV_SELECTOR']
   end
   def serve_static_assets
     ENV['SERVE_STATIC_ASSETS']
   end

 end
end


#class Settings
# include Singleton

# def tld
#   get('TLD')
# end

# private

 #esto es interesante
 #parece usa redis para almacenar las
 #variables de ambiente
# def get(key)
#   redis.get(key).presence || ENV[key]
# end

# def redis
#   @redis ||= Redis.new(url: ENV.fetch("REDIS_URL"))
# end
#end

#ake advantage of the settings object
#f you decided to use the settings object, you can easily stub the object to get the desired value without touching the ENV itself:
#settings = double(api_key: '1234567890')
#expect(Settings).to receive(:instance).and_return(settings)
