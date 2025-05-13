Rails.application.reloader.to_prepare do



#mode= ENV['WABA_MODE'] ? ENV['WABA_MODE'] : 'sandbox'
#Rails.env.test? ? WABA_MODE='sandbox' : WABA_MODE=mode
WabaCfg = Cfg.new('waba_cfg.yml', 'live')
#AGENDA = ::Graph::Agenda.new
#AE_SECRET = ENV['AE_SECRET'] ? ENV['AE_SECRET'] : '' 
#AE_ID = ENV['AE_ID'] ? ENV['AE_ID'] : '' 
TOKEN = ENV['META_USER_TOKEN'] ? ENV['META_USER_TOKEN'] : '' 



end
