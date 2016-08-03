require 'timeout'
module WeiboUtils
  module Http

    def get_with_login(url, is_ajax = false)
      delay
      page = tget(url)
      return page if is_ajax && page.is_a?(Mechanize::File)
      page = ensure_not_captcha_page(page)
      page = ensure_logined_page(page, url)
      page
    end

    def tget(url)
      begin
        page = Timeout::timeout(@timeout) { @weibos_spider.get(url) }
      rescue Timeout::Error, Mechanize::ResponseReadError, Errno::ETIMEDOUT, Net::HTTP::Persistent::Error, 
      Net::HTTPNotImplemented, Net::HTTPBadGateway
        if @retry_time >= 3
          @retry_time = 0
          xproxy
        else
          @retry_time += 1
        end
        retry
      rescue Exception => e
        ensure_use_logout
        logger.fatal("HtmlError")
        logger.fatal(page.search("body").text)        
      end
    ensure
      @retry_time = 0
      return page
    end

    def jget(url)
      delay
      page = tget(url)
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

    def ensure_use_logout
      @account.on_crawl =false
      @account.save
    end

    def save_x_captcha
      pcurl = "http://s.weibo.com/ajax/pincode/pin?type=sass&amp;ts=#{Time.now.to_i}"
      cap = Captcha.create
      file_name = cap.id.to_s
      tget(pcurl).save_as("./public/captchas/#{file_name}.png")
      @x_captcha = input_captcha(cap)
      cap
    ensure
      cap.destroy
      FileUtils.mv("./public/captchas/#{file_name}.png", "./public/captchas/#{cap.code}.png") if File.exist?("./public/captchas/#{file_name}.png")
      File.delete("./public/captchas/#{file_name}.png") 
    end

    def ensure_not_captcha_page(page)
      # captcha_pice = get_script_html(page, 'pl_common_sassfilter')
      # captcha_pice = get_field(page, '#pl_common_sassfilter') unless captcha_pice.present?
      # if captcha_pice.present?
      #   cap = save_x_captcha
      #   page_uri = page.uri.to_s
      #   ret = @weibos_spider.post("http://s.weibo.com/ajax/pincode/verified?__rnd=#{rnd}", {secode: @x_captcha, type: 'sass', pageid: 'weibo' })
      #   ret = JSON.parse(ret.body)
      #   if ret["code"] == "100000"
      #     cap.update_attribute(:is_correct, true)
      #     return tget(page_uri)
      #   else
      #     cap.update_attribute(:is_correct, false)
      #     return ensure_not_captcha_page(page)
      #   end
      # end
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