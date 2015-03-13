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
    if prxs.count < 50
      get_from_dl
      prxs = where(:is_deleted => false).order("last_use DESC")
    end
    while true
      prxs.each do |prx|
        next if prx.account
        if prx.confirm
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
    # url = "http://tiqu.daili666.com/ip/?tid=558226031849865&num=20&area=北京&filter=on"
    url = "http://www.kuaidaili.com/api/getproxy/?orderid=902587926588664&num=30&area=%E4%B8%AD%E5%9B%BD&browser=1&protocol=1&method=1&an_ha=1&sp1=1&sp2=1&sort=0&format=text&sep=4"
    http_client.get(url) do |page|
      proxies = page.body.split('|')
      proxies.each do |prp|
        prp = prp.split(',')[0] # only kuaidaili
        pr = prp.split(':')
        if pr[1].match(/^\d+$/)
          ::Proxy.find_or_create_by(ip: pr[0], port: pr[1])
        else
          sleep(20)
        end
      end
    end
  end

  def set_delete
    self.is_deleted = true
    self.save
  end

  def confirm
    http_client = Mechanize.new
    http_client.open_timeout = 5 
    http_client.read_timeout = 4
    http_client.idle_timeout = 3
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
      self.destroy
    end
    is_confirm
  end

end