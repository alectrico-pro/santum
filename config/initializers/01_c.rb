Rails.application.reloader.to_prepare do

C = Cfg.new('cfg.yml', ENV['ENV_SELECTOR'])

end
