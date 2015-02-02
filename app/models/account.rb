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

  field :level,             :type => Integer,  :default => 0

  has_one :proxy

  scope :can_used, ->{ where(:on_crawl => false)}

  index({ username: 1, password: 1, last_use: 1})


  def self.get_one
    where(:on_crawl => true).all.each do |ac|
      if Time.now.to_i - ac.last_use > 120
        ac.on_crawl = false
        ac.save
      end
      ac.destroy if ac.level > 7
    end
    ret = where(:on_crawl => false).order("last_use ASC").order("level last_use ASC").first
    if ret.proxy
      return ret 
    else
      ret.proxy = ::Proxy.get_one
    end
    ret.use_count = Time.now.to_i
    ret.save
    ret
  end

end