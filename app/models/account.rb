# encoding: utf-8
class Account
  include Mongoid::Document

  field :uid,                   :type => String
  field :username,              :type => String
  field :password,              :type => String

  field :location,              :type => String

  field :last_use,              :type => Integer, :default => Time.now.to_i
  field :use_count,             :type => Integer, :default => 0

  field :on_crawl,              :type => Boolean, :default => false

  field :level,                 :type => Integer,  :default => 0

  has_one :proxy

  scope :can_used, ->{ where(:on_crawl => false)}

  index({ username: 1, password: 1, last_use: 1})

  def self.get_one
    self.clear
    ret = where(:on_crawl => false).order("last_use ASC").order("level last_use ASC").first
    ret.touch 
    ret.proxy = ::Proxy.get_one unless ret.proxy
    sleep(rand(1..3))
    ret
  end

  def self.clear
    where(:on_crawl => true).all.each do |ac|
      if Time.now.to_i - ac.last_use > 120
        ac.on_crawl = false
        ac.save
      end
      ac.destroy if ac.level > 7
    end  end

  def touch
    self.update on_crawl: true, last_use: Time.now.to_i
  end

  def use
    self.update on_crawl: true, last_use: Time.now.to_i, use_count: (use_count + 1)
  end

  def idle
    self.update on_crawl: false, last_use: Time.now.to_i, use_count: 0
  end

end