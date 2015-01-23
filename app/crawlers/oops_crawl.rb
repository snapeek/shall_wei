require 'pry'
require 'mongoid'
require 'logger'
require  File.expand_path("../micro_spider", __FILE__)
require 'active_support/core_ext/object/blank'

Dir["#{File.dirname(__FILE__)}/../models/*.rb"].each {|path| require path} 
Dir["#{File.dirname(__FILE__)}/baidu/*.rb"].each {|path| require path} 
Mongoid.load!(File.expand_path("../../../config/mongoid.yml", __FILE__), :development)

class OopsCrawl
  include BaiduUtils::News

  attr_accessor :logger, :delay_times

  def initialize(args = nil)
    @logger = Logger.new(STDOUT)
    # @logger = Logger.new("log/weibo_crawl.log", 'daily')
    @broken_paths = []
    @delay_times = 1..2
  end

end




