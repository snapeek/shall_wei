require 'pry'
require 'mechanize'
require 'mongoid'
require 'logger'
require 'active_support/core_ext/object/blank'
require 'yaml'

Dir["#{File.dirname(__FILE__)}/../models/*.rb"].each {|path| require path} 
Dir["#{File.dirname(__FILE__)}/weibo/*.rb"].each {|path| require path} 
Mongoid.load!(File.expand_path("../../../config/mongoid.yml", __FILE__), :development)

class WeiboSpider 
  include WeiboUtils::Login
  include WeiboUtils::Proxy
  include WeiboUtils::Hacks
  include WeiboUtils::Http

  attr_accessor :logger, :username, :password, :account, :last_use, :bak

  def initialize(logger)
    @logger = logger
    @login_count ||= 0
    @login_count += 1
    @weibos_spider = Mechanize.new do |m|
      m.ssl_version, 
      m.verify_mode = 'SSLv3', 
      OpenSSL::SSL::VERIFY_NONE
    end
    # @last_use = Time.now
    @relogin_count = 0
    @cpc_count = 0
    @delay_times = 2..5
    @account = Account.get_one
    @username = @account.username # "gwksgujy0@sina.cn"
    @password = @account.password # "563646018505"
    @weibos_spider.user_agent_alias = ['Windows IE 9', 'Mac Safari', 'Mac Firefox', 'Windows Mozilla'].shuffle.first
    # @weibos_spider.user_agent_alias = 'Mac Safari'
    set_proxy
    @weibos_spider
  end

  def delay
    tt = Time.now - Time.at(@account.last_use)
    ts = rand(@delay_times)
    sleep(ts - tt) if ts > tt
  end  
end

class WeiboCrawl
  include WeiboUtils::Hacks
  include WeiboUtils::Search
  include WeiboUtils::DayCount
  include WeiboUtils::Brand
  include WeiboUtils::UserInfo
  include WeiboUtils::Repost

  attr_accessor :logger, :delay_times, :search_options, :current_weibo_spider, :account

  def initialize(args = nil)
    @logger = Logger.new(STDOUT)
    # @logger = Logger.new("log/weibo_crawl.log", 'daily')
    @broken_paths = []
    @delay_times = 2..5
    @weibos_spiders = []
    3.times { add_spider }
    @retry_time = 0
    @weibos_spiders.each_with_index{|ws, idx| ws.bak = @weibos_spiders[(-idx) - 1] }
    weibos_spider
  end

  def add_spider
    ws = WeiboSpider.new(@logger)
    @weibos_spiders << ws
    ws.login
    # Thread.fork{ ws.login }
    ws
  end

  def delay
    tt = Time.now - Time.at(account.last_use)
    ts = rand(@delay_times)
    sleep(ts - tt) if ts > tt
  end  

  def get_with_login(url, is_ajax = false)
    weibos_spider.get_with_login(url, is_ajax)
  end

  def jget(url)
    weibos_spider.jget(url)
  end

  def weibos_spider
    @current_weibo_spider = @weibos_spiders.shuffle.first
  end

  def account
    @current_weibo_spider.account
  end

  def load_status
    Dir.mkdir("tmp/search_status/") unless Dir.exist?("tmp/search_status/")
    options = []
    status_files = Dir["#{File.dirname(__FILE__)}/../../tmp/search_status/*.yaml"]
    puts "发现之前的搜索结果, 输入相应编号继续搜索, 按 Enter 略过.\n\n" if status_files.present?
    status_files.each_with_index do |path, idx| 
      opt = YAML.load_file(path)
      options << opt
      puts "  #{idx + 1}) #{opt[:keyword]} 从#{opt[:starttime]}起的第#{opt[:page] || 1}页"
    end
    print "请输入: " if status_files.present?
    _input = gets
    opt = options[_input.to_i - 1] if _input.present?
  end
end




