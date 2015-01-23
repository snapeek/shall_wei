class Proxy

  include Mongoid::Document

  field :ip        , :type => String
  field :port      , :type => String
  field :location  , :type => String
  field :type      , :type => String 
  field :last_use  , :type => Integer, :default => Time.now.to_i
  field :use_count , :type => Integer, :default => 0
  field :is_deleted, :type => Boolean, :default => false 

  belongs_to :account
  
  scope :can_used, ->{ where(:is_deleted => false)}
  
  validates :ip, presence: true, uniqueness: true
  validates :port, presence: true

  scope :location_at, ->(_location){ where(:location => /#{_location}/) }

  def self.get_one(_location = nil)
    ret = nil
    prxs = where(:is_deleted => false).order("last_use DESC")
    if prxs.count < 40
      get_from_dl
      prxs = where(:is_deleted => false).order("last_use DESC")
    end
    while true
      p "获取代理"
      prxs.each do |prx|
        next if prx.account
        if prx.nil? || prx.confirm
          ret = prx
          break
        else
          next
        end
      end
      if ret 
        break 
      else   
        get_from_dl
        prxs = where(:is_deleted => false).order("last_use DESC")
      end
    end

    ret
  end

  def host
    "#{type.downcase}://#{ip}"
  end

  def self.get_from_dl
    http_client = Mechanize.new
    url = "http://tiqu.daili666.com/ip/?tid=558226031849865&num=20&area=北京&filter=on"
    http_client.get(url) do |page|
      proxies = page.body.split(/\s+/)
      proxies.each do |prp|
        pr = prp.split(':')
        ::Proxy.create(ip: pr[0], port: pr[1], location: "北京")
      end
    end
  end

  def set_delete
    self.is_deleted = true
    self.save
  end

  def confirm
    http_client = Mechanize.new
    http_client.read_timeout = 5
    # proxy = URI.parse("http://183.221.186.116:8123")
    http_client.set_proxy(ip, port)
    http_client.user_agent_alias = 'Mac Safari'
    _ip = ""
    a = Time.now
    begin
      http_client.get("http://www.ip.cn/") do |page|
        _ip = page.search("#result code").text
      end
    rescue Exception => e
      self.set_delete
    end
    b = Time.now
    is_confirm = _ip == self.ip
    is_confirm = false if b - a > 10.seconds
    logger.info "> 验证代理: #{ip}(#{_ip}): #{is_confirm}"
    if is_confirm
      return true
    else
      self.set_delete
    end
    is_confirm
  end

end