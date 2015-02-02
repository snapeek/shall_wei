class CaptchasController < ApplicationController
  before_action :set_captcha, only: [:show, :edit, :update, :destroy]

  # GET /captchas
  # GET /captchas.json
  def index
    @captchas = Captcha.all
  end

  # GET /captchas/1
  # GET /captchas/1.json
  def show
  end

  # GET /captchas/new
  def new
    @captcha = Captcha.new
  end

  # GET /captchas/1/edit
  def edit
  end

  # POST /captchas
  # POST /captchas.json
  def create
    @captcha = Captcha.new(captcha_params)

    respond_to do |format|
      if @captcha.save
        format.html { redirect_to @captcha, notice: 'Captcha was successfully created.' }
        format.json { render :show, status: :created, location: @captcha }
      else
        format.html { render :new }
        format.json { render json: @captcha.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /captchas/1
  # PATCH/PUT /captchas/1.json
  def update
    respond_to do |format|
      if @captcha.update(captcha_params)
        @captcha.save_as
        format.html { redirect_to captchas_path, notice: '验证码填写成功.' }
      else
        format.html { redirect_to captchas_path, notice: '验证码填写失败.' }
      end
    end
  end

  # DELETE /captchas/1
  # DELETE /captchas/1.json
  def destroy
    @captcha.destroy
    respond_to do |format|
      format.html { redirect_to captchas_url, notice: 'Captcha was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_captcha
      @captcha = Captcha.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def captcha_params
      params.require(:captcha).permit(:code)
    end
end
