class ComentariosController < ApplicationController
  before_action :set_reporte

  def create
    @reporte.comentarios.create! params.required(:comentario).permit(:contenido)
    redirect_to @reporte
  end

  private
    def set_reporte
      @reporte = Reporte.find(params[:reporte_id])
    end
end
