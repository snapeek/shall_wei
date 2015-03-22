require 'timeout'
module WeiboUtils
  module Http

    def get_with_login(url, is_ajax = false)
      delay
      ensure_use_count
      page = http_get(url)
      return page if is_ajax && page.is_a?(Mechanize::File)
      page = ensure_not_captcha_page(page)
      # page = ensure_not_relogin_page(page)
      page = ensure_logined_page(page, url)
    rescue SystemExit, Interrupt
      ensure_use_logout
      logger.fatal("SystemExit && Interrupt")
      print "确定要退出吗?(y/n) "
      exit! if gets.include?('y')
    rescue Mechanize::ResponseReadError, Errno::ETIMEDOUT, Net::HTTP::Persistent::Error, 
      Net::HTTPNotImplemented, Net::HTTPBadGateway
      if @retry_time >= 3
        logger.fatal("> 更换代理: HttpError.")
        @retry_time = 0
        xproxy
      retry
        logger.fatal("> 重试连接: HttpError.")
        @retry_time += 1
      end
      retry
    rescue Exception => e
      ensure_use_logout
      logger.fatal("HtmlError:")
      # binding.pry
      logger.fatal(page.search("body").text)
    ensure
      @retry_time = 0
      return page
    end

    def http_get(url)
      redo_times = 0
      @wspage = nil
      while(redo_times < 6 || @wspage == nil)
        begin
          @wspage = Timeout::timeout(@timeout) { @weibos_spider.get(url) }
          break if @wspage
        rescue Timeout::Error => err
          logger.fatal('Timeout!!! execution expired when execute action')
          logger.fatal(err.message)
          logger.fatal(err.backtrace.inspect)
          redo_times += 1
          next if redo_times  < 3
          xproxy
        end
      end
      @wspage
    end

    def get_with_login2(url, is_ajax = false)
      delay
      ensure_use_count
      page = http_get(url)
      return page if is_ajax && page.is_a?(Mechanize::File)
    rescue SystemExit, Interrupt
      ensure_use_logout
      logger.fatal("SystemExit && Interrupt")
      print "确定要退出吗?(y/n) "
      exit! if gets.include?('y')
    rescue Mechanize::ResponseReadError, Errno::ETIMEDOUT, Net::HTTP::Persistent::Error, 
      Net::HTTPNotImplemented, Net::HTTPBadGateway
      if @retry_time >= 3
        logger.fatal("> 更换代理: HttpError.")
        @retry_time = 0
        xproxy
      retry
        logger.fatal("> 重试连接: HttpError.")
        @retry_time += 1
      end
      retry
    rescue Exception => e
      ensure_use_logout
      logger.fatal("HtmlError:")
      # binding.pry
      logger.fatal(page.search("body").text)
    ensure
      @retry_time = 0
      return page
    end

    def jget(url)
      delay
      page = http_get(url)
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

    def is_block_page?(page)
      page.uri.to_s.include?("userblock")
    end

    def ensure_use_count
      # prx = @account.proxy
      if account.use_count > 1000
        logger.fatal("> 更换账号: 原账号已使用#{account.use_count}次.")
        account.idle 
        xaccount(false)
      end
      account.use
    end

    def ensure_use_logout
      @account.on_crawl =false
      @account.save
    end

    def save_x_captcha
      pcurl = "http://s.weibo.com/ajax/pincode/pin?type=sass&amp;ts=#{Time.now.to_i}"
      cap = Captcha.create
      file_name = cap.id.to_s
      http_get(pcurl).save_as("./public/captchas/#{file_name}.png")
      @x_captcha = input_captcha(cap)
    ensure
      cap.destroy
      FileUtils.mv("./public/captchas/#{file_name}.png", "./public/captchas/#{cap.code}.png") if File.exist?("./public/captchas/#{file_name}.png")
      # File.delete("./public/captchas/#{file_name}.png") 
    end

    def ensure_not_captcha_page(page)
      captcha_pice = get_script_html(page, 'pl_common_sassfilter')
      captcha_pice = get_field(page, '#pl_common_sassfilter') unless captcha_pice.present?
      if captcha_pice.present?
        save_x_captcha
        page_uri = page.uri.to_s
        ret = @weibos_spider.post("http://s.weibo.com/ajax/pincode/verified?__rnd=#{rnd}", {secode: @x_captcha, type: 'sass', pageid: 'weibo' })
        ret = JSON.parse(ret.body)
        if ret["code"] == "100000"
          return http_get(page_uri)
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
        logger.info("> 访问出错: 账号被登出,正在重试.")
        login 
        page = get_with_login(url)
      end
      page
    end
  end
end