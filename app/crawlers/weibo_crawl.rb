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

  def initialize
    @logger = $logger
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
    @delay_times = 3..8
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
  include WeiboUtils::Auser
  include WeiboUtils::DayCount
  include WeiboUtils::Brand
  include WeiboUtils::UserInfo
  include WeiboUtils::Repost

  attr_accessor :logger, :delay_times, :search_options, :current_weibo_spider, :account

  def initialize(args = nil)
    $logger ||= Logger.new(STDOUT)
    # $logger ||= Logger.new("log/weibo_crawl.log", 'daily')
    @logger = $logger
    @broken_paths = []
    @delay_times = 2..5
    @weibos_spiders = []
    1.times { add_spider }
    @retry_time = 0
    @weibos_spiders.each_with_index{|ws, idx| ws.bak = @weibos_spiders[(-idx) - 1] }
    weibos_spider
  end

  def add_spider
    ws = WeiboSpider.new
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
    @current_weibo_spider = @weibos_spiders.sample
  end

  def account
    @current_weibo_spider.account
  end
end




