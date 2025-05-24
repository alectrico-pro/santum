class ReportesController < ApplicationController
  include Linea

  #before_filter :restrict_use
  #def restrict_user
  #  unless current_user.allowed?
  #   redirect_to root_path
  # end
  #end

  before_action :set_reporte, only: %i[ show edit update destroy avisar  ]
  after_action  :set_current_fono, only: %i[ show edit update destroy avisar ]


  # GET /reporte
  def avisar
    respond_to do |format|
      if @reporte.reservar
        format.html { redirect_to reportes_url, notice: "Se ha avisado a los colaboradores." }
        format.turbo_stream { flash.now[:notice] = "Se ha avisado a los colaboradores."}
        format.json { render :avisar, status: :ok, location: @reporte }
      end
    end
  end

  # GET /reportes or /reportes.json
  def index
    @reportes = Reporte.all
  end

  # GET /reportes/1 or /reportes/1.json
  def show
  end

  # GET /reportes/new
  def new
    @reporte = Reporte.new
  end

  # GET /reportes/1/edit
  def edit
  end

  # POST /reportes or /reportes.json
  def create
    @reporte = Reporte.new(reporte_params)

    respond_to do |format|
      if @reporte.save
        format.html { redirect_to @reporte, notice: "Revise su whatsapp para confirmar." }
        format.turbo_stream { flash.now[:notice] = "Revise su Whatsapp para confirmar."}
        format.json { render :show, status: :created, location: @reporte }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @reporte.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /reportes/1 or /reportes/1.json
  def update
    respond_to do |format|
      if @reporte.update(reporte_params)
        format.html { redirect_to @reporte, notice: "El Reporte ha sido actualizado." }
        format.turbo_stream { flash.now[:notice] = "El reporte ha sido actualizado."}
        format.json { render :show, status: :ok, location: @reporte }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @reporte.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /reportes/1 or /reportes/1.json
  def destroy
    @reporte.destroy
    respond_to do |format|
      format.html { redirect_to reportes_url, notice: "El reporte ha sido destruído." }
      format.turbo_stream { flash.now[:notice] = "El reporte ha sido destruído."}
      format.json { head :no_content }
    end
  end

  private
    #Método muy simple para organizar la sessión de usuario
    def set_current_fono
      linea.info "Seteando current_fono en el controlado reportes"
      cookies.encrypted[:current_fono] = @reporte.fono #if @reporte.confirmado
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_reporte
      begin
        @reporte = Reporte.find(params[:id])
      rescue
        redirect_to root_path 
      end
    end

    # Only allow a list of trusted parameters through.
    def reporte_params
      params.require(:reporte).permit(:nombre, :fono, :contenido, :confirmado)
    end
end
