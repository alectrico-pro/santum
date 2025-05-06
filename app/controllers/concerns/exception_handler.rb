module ExceptionHandler

  extend ActiveSupport::Concern

  #provide the more graceful 'included' method
  class InvalidToken         < StandardError; end

  included do

    rescue_from InvalidToken do |e|
      respond_to do |format|
        format.html {  html_response({ message: "Token No Es válido" }) }
	format.json {  json_response({ message: e.message }, :unprocessable_entity ) }
      end
    end

    rescue_from ActiveRecord::RecordNotFound do |e|
      respond_to do |format|
        format.html {  html_response({ message: e.message }) }
        format.json {  json_response({ message: e.message }, :not_found ) }
      end
    end

    rescue_from ActiveRecord::RecordInvalid do |e|
      respond_to do |format|
        format.html {  html_response({ message: e.message }) }
        format.json {  json_response({ message: e.message }, :unprocessable_entity ) }
      end
    end

    rescue_from NotOriginAllowed do |e|

     respond_to do |format|
        format.html {  html_response({ message: e.message }) }
        format.json {  json_response({ message: e.message }, :unauthorized) }
      end

    end

    rescue_from NotAuthTokenPresent do |e|
     respond_to do |format|
        format.html {  html_response({ message: e.message }) }
        format.json {  json_response({ message: e.message }, :unauthorized) }
      end
    end

    rescue_from RequestNotAuthorized do |e|
      respond_to do |format|
        format.html {  html_response({ message: e.message }) }
        format.json {  json_response({ message: e.message }, :unauthorized) }
      end
    end

    rescue_from NotUser do |e|
      respond_to do |format|
        format.html {  html_response({ message: e.message }) }
        format.json {  json_response({ message: e.message }, :unauthorized) }
      end
    end

    rescue_from InvalidCredentials do |e|
      #require ok de estatus para que lo procese amp-runtime
      respond_to do |format|
        format.html {  html_response({ message: e.message }) }
        format.json {  json_response({ message: e.message }, :ok) }
      end
    end

    rescue_from PresupuestoNotToBeDeleted do |e|
      #require ok de estatus para que lo procese amp-runtime
      respond_to do |format|
        format.html {  html_response({ message: e.message }) }
        format.json {  json_response({ message: e.message }, :ok) }
      end
    end


  end

end
