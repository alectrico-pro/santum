class ApiController < ActionController::API

  include ActionController::MimeResponds
  include ExceptionHandler
  include Response

  include NotOriginAllowed
  include NotUsuario
  include NotAuthTokenPresent
  include RequestNotAuthorized
  include ExceptionHandler
  include InvalidCredentials

  before_action :cors 
  before_action :noindex


  protected

  def remote_hostname
   #require 'resolv'
    Resolv.getname(request.remote_ip)
  end


  def noindex
    response.headers['X-Robots-Tag'] = 'noindex'
  end

  def cache_config
    expires_in 30.minutes, :public => true
  end

  def no_cache
    expires_in 10.seconds, :public => true
  end

  def cors_no_amp
    linea.info params.inspect
    linea.info "en cors_no_amp"

    unless request.headers['Origin']
      linea.info "No se encontró headers de Origin"
      raise NotOriginAllowed
      return
    else
      linea.info "Existe el header Origin"
      @origen = request.headers['Origin']
      linea.info "@origin es evaluado a:"
      linea.info @origen
    end


    if URLS_PERMITIDAS
      linea.info "Existe el registro de URLS_PEMITIDAS"
      if URLS_PERMITIDAS and @origen and @origen.in?( URLS_PERMITIDAS )
        linea.info "Todo bien"
      else
        linea.info "#{@origen} no está en #{URLS_PERMITIDAS.inspect}"
        raise NotOriginAllowed
        return
      end
    else
      linea.info "No existe registro de URLS_PERMITIDAS"
      raise NotOriginAllowed
      return
    end

    if
      response.headers['AMP-Access-Control-Allow-Source-Origin'] = @origen
      response.headers['Access-Control-Allow-Origin'] = @origen
      response.headers['Access-Control-Expose-Headers'] = 'AMP-Access-Control-Allow-Source-Origin'
    else
      if request.headers['AMP-Same-Origin']
      else
        raise NotOriginAllowed
        return
      end
    end
    linea.info "Terminando bien en cors"
  end


  def cors
    linea.info params.inspect
    @origen =  params[:__amp_source_origin] || params[":__amp_source_origin"]

    linea.info "en cors"
    linea.info @origen

    unless request.headers['Origin']
      linea.info "No se encontró headers de Origin"
      raise NotOriginAllowed
      return
    else
      linea.info "Existe el header Origin"
    end


    if URLS_PERMITIDAS
      linea.info "Existe el registro de URLS_PEMITIDAS"
      if URLS_PERMITIDAS and @origen and @origen.in?( URLS_PERMITIDAS )
        linea.info "Todo bien"
      else
        linea.info "#{@origen} no está en #{URLS_PERMITIDAS.inspect}"
        raise NotOriginAllowed
        return
      end
    else
      linea.info "No existe registro de URLS_PERMITIDAS"
      raise NotOriginAllowed
      return
    end

    if
      response.headers['AMP-Access-Control-Allow-Source-Origin'] = @origen
      response.headers['Access-Control-Allow-Origin'] = @origen
      response.headers['Access-Control-Expose-Headers'] = 'AMP-Access-Control-Allow-Source-Origin'
    else
      if request.headers['AMP-Same-Origin']
      else
        raise NotOriginAllowed
        return
      end
    end
    linea.info "Terminando bien en cors"
  end

  def reader
    authenticate_request
  end

  def authenticate_request
    # linea.info "En authenticate_request"
    unless params[:auth_token]
      raise NotAuthTokenPresent
      return
    end
    unless Gestion::Usuario.count > 0
      raise NotUsuario
      return
    end
    @current_usuario = AuthorizeApiRequestByParams.call(params).result
  end

end
