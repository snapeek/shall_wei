class CaptchasController < ApplicationController
  before_action :create, :set_captcha, only: [:show, :edit, :update, :destroy]

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

  # POST /captchas.json
  def create
    respond_to do |format|
      if @captcha.update(captcha_params)
        while true
          sleep(1)
          @captcha.reload
          if @captcha.code == true
            format.json { result: true }
            break
          elsif @captcha.code == false
            format.json { result: false }
            break
          else
            sleep(4)
            next
          end
        end
      else
        format.json { result: false }
      end
    end
  end

  # PATCH/PUT /captchas/1
  # PATCH/PUT /captchas/1.json
  def update
    respond_to do |format|
      if @captcha.update(captcha_params)
        format.html { redirect_to captchas_path, notice: '验证码填写成功.' }
        format.json {  }
      else
        format.html { redirect_to captchas_path, notice: '验证码填写失败.' }
        format.json {  }
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
