class KibersController < ApplicationController
  before_action :set_kiber, only: [:show, :edit, :update, :destroy]

  # GET /kibers
  # GET /kibers.json
  def index
    @nc = WeiboUser.need_crawl.count
  end

  # GET /kibers/1
  # GET /kibers/1.json
  def show
  end

  # GET /kibers/new
  def new
    @kiber = Kiber.new
  end

  # GET /kibers/1/edit
  def edit
  end

  # POST /kibers
  # POST /kibers.json
  def create
    @kiber = Kiber.new(kiber_params)

    respond_to do |format|
      if @kiber.save
        format.html { redirect_to @kiber, notice: 'Kiber was successfully created.' }
        format.json { render :show, status: :created, location: @kiber }
      else
        format.html { render :new }
        format.json { render json: @kiber.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /kibers/1
  # PATCH/PUT /kibers/1.json
  def update
    respond_to do |format|
      if @kiber.update(kiber_params)
        format.html { redirect_to @kiber, notice: 'Kiber was successfully updated.' }
        format.json { render :show, status: :ok, location: @kiber }
      else
        format.html { render :edit }
        format.json { render json: @kiber.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /kibers/1
  # DELETE /kibers/1.json
  def destroy
    @kiber.destroy
    respond_to do |format|
      format.html { redirect_to kibers_url, notice: 'Kiber was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_kiber
      @kiber = Kiber.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def kiber_params
      params[:kiber]
    end
end
