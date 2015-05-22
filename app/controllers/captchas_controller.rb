class CaptchasController < ApplicationController
  before_action :set_captcha, only: [:show, :edit, :update, :destroy]
  protect_from_forgery :except => :create  
  
   # you can disable csrf protection on controller-by-controller basis:  
   skip_before_filter :verify_authenticity_token
  # GET /captchas
  # GET /captchas.json
  def index
    @captchas = Captcha.where(:is_correct => nil)
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
    @captcha = Captcha.where(:id => params[:captcha][:id]).first
    respond_to do |format|
      if @captcha && @captcha.update(captcha_params)
        if [4,5].include @captcha.code.length
          format.json { render :json => {:result => true} }
        else
          format.json { render :json => {:result => false} }
        end
          @captcha.destroy
        # while true
        #   sleep(1)
        #   @captcha.reload
        #   case @captcha.is_correct
        #   when true
        #     format.json { render :json => {:result => true} }
        #     break
        #   when false
        #     format.json { render :json => {:result => false} }
        #     break
        #   else
        #     sleep(4)
        #     next
        #   end
        #   @captcha.destroy
        # end
      else
        format.json { render :json => {:result => false} }
      end
    end
  end

  # PATCH/PUT /captchas/1
  # PATCH/PUT /captchas/1.json
  def update
    respond_to do |format|
      if @captcha.update(captcha_params)
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
