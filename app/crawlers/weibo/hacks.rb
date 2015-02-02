module WeiboUtils
  module Hacks

    def get_with_login(url, is_ajax = false)
      delay
      ensure_use_count
      page = @weibos_spider.get(url)

      return page if is_ajax && page.is_a?(Mechanize::File)

      page = ensure_not_captcha_page(page)
      # page = ensure_not_relogin_page(page)
      page = ensure_logined_page(page, url)
      raise "UserBlocked" if is_block_page?(page)
    rescue SystemExit, Interrupt
      ensure_use_logout
      logger.fatal("SystemExit && Interrupt")
      print "确定要退出吗?(y/n) "
      exit! if gets.include?('y')
    rescue Net::HTTP::Persistent::Error
      delay
      retry
    rescue Errno::ECONNREFUSED
      xproxy
      retry
    rescue Exception => e
      ensure_use_logout
      logger.fatal("HtmlError:")
      # binding.pry
      logger.fatal(page.search("body").text)
    ensure
      return page
    end

    def jget(url)
      delay
      page = @weibos_spider.get(url)
    rescue SystemExit, Interrupt
      logger.fatal("SystemExit && Interrupt")
      print "确定要退出吗?(y/n) "
      exit! if gets.include?('y')
    rescue Net::HTTP::Persistent::Error
      delay
      retry      
    rescue Exception => e
      logger.fatal("HtmlError:")
      logger.fatal(page.search("body").text)
    ensure
      return page
    end

    def get_attr(node, attr_name)
      # logger.info "> 开始解析: #{attr_name}"
      return "" unless node.present?
      begin
        ret = node.attr(attr_name).to_s
      rescue Exception => err
        # binding.pry
        logger.fatal("> 提取出错: `#{attr_name}`")
        logger.fatal(err)
        logger.fatal(err.backtrace.slice(0,5).join("\n"))
      end
      if block_given?
        begin
          ret = yield(ret)
        rescue Exception => err
          logger.fatal("> 执行出错:")
          logger.fatal(err)
          logger.fatal(err.backtrace.slice(0,5).join("\n"))
        end
      end
      ret.present? ? ret : ""
    end

    def get_field(node, selector, attr_name = nil)
      ret = nil
      ret = node.search(selector).first
      ret = attr_name ? get_attr(ret, attr_name) : ret
      ret = yield(ret) if block_given?
    rescue Exception => err
      logger.fatal("> 执行出错:")
      logger.fatal(err)
      logger.fatal(err.backtrace.slice(0,5).join("\n")) 
    ensure   
      return ret.present? ? ret : ""
    end

    def get_fields(node, selector, attr_name = nil)
      ret = nil
      ret = node.search(selector)
      ret = attr_name ? ret.map{ |e| get_attr(e, attr_name)} : ret
      ret = ret.map{|pice| yield(pice)} if block_given?
    rescue Exception => err
      logger.fatal("> 执行出错:")
      logger.fatal(err)
      logger.fatal(err.backtrace.slice(0,5).join("\n")) 
    ensure   
      return ret.present? ? ret.select{|e| e.present? } : []
    end

    def find_fields(node, selector)
      logger.info "> 开始解析: #{selector}"
      ret = node.search(selector)
    rescue Exception => err
      logger.fatal("> 解析出错: `#{selector}`")
      logger.fatal(err)
      logger.fatal(err.backtrace.slice(0,5).join("\n")) 
    ensure
      return ret
    end

    def get_script_html(page, ns)
      scripts = page.search("script")
      scripts = scripts.map{|script| begin JSON.parse(script.child.to_s.match(/\{[\w\W]*\}/).to_s) rescue "" end}
      if ns.is_a? Regexp
        pice = scripts.select{|script| script["ns"] =~ ns || script["pid"] =~ ns || script["domid"] =~ ns}.first
      else
        pice = scripts.select{|script| script["ns"] == ns || script["pid"] == ns || script["domid"] == ns}.first
      end

      return Nokogiri.HTML(pice["html"]) if pice
    end

    def get_json_html(page)
      joo = JSON::parse(page.body)['data']
      Nokogiri.HTML(joo["html"]) if joo
    end

    def get_config(page, attr_name = "")
      joos = page.search("script")
      joo = joos.select{|joo| joo.to_s.include?("var $CONFIG = {};")}.first.to_s
      if attr_name.present?
        return joo.match(/\$CONFIG\[\'#{attr_name}\'\][\s=\']*([\w]*)/).try("[]", 1)
      else
        joo
      end
    end

    def filtered(source, filter_sources)
      fs_flag = true
      filter_sources.each do |fs|
        fs_flag = false if source.match(fs)
      end
      fs_flag
    end

    def str_62_to_10(str62)
      i10 = 0
      i = 1
      str62.each_char do |c|
        n = str62.length - i
        i += 1
        i10 += str62keys.index(c) * (62 ** n)
      end
      i10
    end

    def str_10_to_62(int10)
      s62 = ''
      r = 0
      while int10 != 0
        s62 = str62keys[int10 % 62] + s62
        int10 = int10 / 62
      end
      s62
    end

    def mid_to_str(mid) 
      str = ''
      mid = mid.to_s.dup
      (mid.length / 7 + 1).times do |i|
        if mid.length >= 7
          num = str_10_to_62(mid.slice!(-7, 7).to_i)
        else
          num = str_10_to_62(mid.to_i)
        end
        str = num + str
      end
      str
    end

    def str_to_mid(str)
      mid = ""
      str = str.dup
      (str.length / 4 + 1).times do |i|
        offset = i < 0 ? 0 : i
        if str.length >= 4
          num = str_62_to_10(str.slice!(-4, 4))
        else
          num = str_62_to_10(str)
        end
        mid = mid.ljust(7, '0') if (offset > 0) 
        mid = num.to_s + mid
      end
      mid 
    end

    def rnd
      Time.now.to_i * 1000 + rand(1000)
    end

    def str62keys
    [
      "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
      "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
      "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"
    ]
    end

    private

    def is_block_page?(page)
      page.uri.to_s.include?("userblock")
    end

    def ensure_use_count
      # prx = @account.proxy
      if @account.use_count > 1000
        @account.use_count = 0
        @account.last_use = Time.now.to_i
        @account.on_crawl = false
        @account.save
        xaccount(false)
        @account.use_count = 0
        set_proxy
        login
      end
      prx = @account.proxy
      set_proxy unless prx 
      prx.last_use = @account.last_use   = Time.now.to_i
      @account.use_count += 1
      @account.on_crawl = true
      @account.save
      prx.save
    end

    def ensure_use_logout
      @account.on_crawl =false
      @account.save
    end

    def ensure_not_relogin_page(page)
      if page.uri.to_s.include?("login.sina.com.cn/sso/login.php?")
        logger.info("> 访问出错: 账号登陆状态被重置,正在重试.")
        wlr = page.search('script').to_s.match(/.replace\([\"\']([\w\W]*)[\"\']\)/)[1]
        page = @weibos_spider.get(wlr)
      elsif page.uri.to_s.include?("http://passport.weibo.com/visitor/visitor?a=enter")
        logger.info("> 访问出错: 账号登陆状态被重置,正在重试.")
        wlr = page.uri.to_s
        page = @weibos_spider.get(wlr)
      end
      save_cookies
      page
    end

    def save_x_captcha
      pcurl = "http://s.weibo.com/ajax/pincode/pin?type=sass&amp;ts=#{Time.now.to_i}"
      cap = Captcha.create
      file_name = cap.id.to_s
      @weibos_spider.get(pcurl).save_as("./public/captchas/#{file_name}.png")
      @x_captcha = input_captcha(cap)
    ensure
      cap.destroy
      FileUtils.mv("./public/captchas/#{file_name}.png", "./public/captchas/#{cap.code}.png") if File.exist?("./public/captchas/#{file_name}.png")
      # File.delete("./public/captchas/#{file_name}.png") 
    end

    def ensure_not_captcha_page(page)
      if captcha_pice = get_script_html(page, 'pl_common_sassfilter')
        save_x_captcha
        page_uri = page.uri.to_s
        ret = @weibos_spider.post("http://s.weibo.com/ajax/pincode/verified?__rnd=#{rnd}", {secode: @x_captcha, type: 'sass', pageid: 'weibo' })
        ret = JSON.parse(ret.body)
        if ret["code"] == "100000"
          return @weibos_spider.get(page_uri)
        else
          return ensure_not_captcha_page(page)
        end
      end
      page
    end

    def ensure_logined_page(page, url)
      if get_config(page, "islogin").to_s == '1'
        page
      else
        logger.info("> 访问出错: 账号被登出,正在重试(#{@relogin_count}).")
        if @relogin_count >= 3
          xaccount
        else
          relogin
          @relogin_count += 1 
        end
        page = @weibos_spider.get(url)
        page = ensure_not_relogin_page(page)
      end
      page
    end
  end
end