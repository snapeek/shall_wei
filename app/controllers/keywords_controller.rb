class KeywordsController < ApplicationController
  before_action :set_keyword, only: [:show, :edit, :update, :destroy, :search_day_count, :new_search, :weibo]

  # GET /keywords
  # GET /keywords.json
  def index
    @keywords = Keyword.all
  end

  # GET /keywords/1
  # GET /keywords/1.json
  def show
  end

  # GET /keywords/new
  def new
    @keyword = Keyword.new
  end

  def baidu_news
    
  end

  def wpath
    
  end

  def method_name
    
  end

  def weibo
    @weibos = @keyword.weibos.hot
  end

  def repost
    Wpath.perform_async params[:mid]
    respond_to do |format|
      if @keyword.save
        format.html { redirect_to @keyword, notice: '开始爬取!' }
        format.json { render :show, status: :created, location: @keyword }
      else
        format.html { render :new }
        format.json { render json: @keyword.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /keywords/1/edit
  def edit
  end

  def new_search
    kid = "#{params[:starttime]}-#{params[:all_count]}"
    params[:starttime] = Time.parse(params[:starttime]).to_i
    k = @keyword.kibers.create(
      starttime: params[:starttime],
      crdtime: params[:starttime],
      endtime: params[:starttime] + 1.days,
      all_count: params[:all_count],
      kid: kid,
      gap: 1
    )
    # binding.pry
    @keyword.save
    # WeiboSearchWorker.perform_async k.id.to_s
    respond_to do |format|
      if @keyword.save
        format.html { redirect_to @keyword, notice: '开始爬取!' }
        format.json { render :show, status: :created, location: @keyword }
      else
        format.html { render :new }
        format.json { render json: @keyword.errors, status: :unprocessable_entity }
      end
    end
  end

  def search_day_count
    DayCountWorker.perform_async @keyword.id.to_s
    respond_to do |format|
      if @keyword.save
        format.html { redirect_to @keyword, notice: '开始爬取!' }
        format.json { render :show, status: :created, location: @keyword }
      else
        format.html { render :new }
        format.json { render json: @keyword.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /keywords
  # POST /keywords.json
  def create
    @keyword = Keyword.new(keyword_params)

    respond_to do |format|
      if @keyword.save
        format.html { redirect_to @keyword, notice: 'Keyword was successfully created.' }
        format.json { render :show, status: :created, location: @keyword }
      else
        format.html { render :new }
        format.json { render json: @keyword.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /keywords/1
  # PATCH/PUT /keywords/1.json
  def update
    respond_to do |format|
      if @keyword.update(keyword_params)
        format.html { redirect_to @keyword, notice: 'Keyword was successfully updated.' }
        format.json { render :show, status: :ok, location: @keyword }
      else
        format.html { render :edit }
        format.json { render json: @keyword.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /keywords/1
  # DELETE /keywords/1.json
  def destroy
    @keyword.destroy
    respond_to do |format|
      format.html { redirect_to keywords_url, notice: 'Keyword was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_keyword
      @keyword = Keyword.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def keyword_params
      permited_params = params.require(:keyword).permit(:content, :starttime, :endtime, :day_count)
      permited_params["starttime"] = Time.parse(permited_params["starttime"]).to_i
      permited_params["crdtime"]   = permited_params["starttime"]
      permited_params["endtime"]   = Time.parse(permited_params["endtime"]).to_i
      permited_params
    end
end
