module Response

  def html_response(mensaje, status = :ok)
    @result =  result_hash = {
               :status => 404,
               :error => mensaje,
               :header => "¡Ocurrió un Error!",
               :icon => "fail",
	       :message => "Bah! Algo inesperado ocurrió cuando Ud. intentaba hacer algo en la plataforma alectrico.cl. "
            }
     #render  :template => '/comercio/ordenes/return_webpay', :action => :show, :id => -1,  :formats => [:html], :layout => 'layouts/api/error_layout'
     render :template => 'api/show', :action => :show, :status => 404, :formats => [:html], :layout => 'layouts/api/error_layout'
  end

  def json_response(object, status = :ok)
    render json: object, status: status
  end

end
