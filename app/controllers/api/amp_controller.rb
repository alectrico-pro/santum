module Api
  #class AmpController < ActionController::API
  class AmpController < ApiController
   include ActionController::MimeResponds 
   include Linea

   protected
    def check_cookies
      m = /_#{C.tld}_site_session=(.*)/.match(request.headers['HTTP_COOKIE'])
      ck = cookies["_#{C.tld}_site_session".to_sym]
      if m and ck and ck =! m[1]
        raise "Las cookies no coinciden"
      end
    end
  end
end
