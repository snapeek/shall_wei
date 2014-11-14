module WeiboUtils
  module Login
    module ClassMethods
      
    end
    
    module InstanceMethods

      public

      def login(rel = false)
        if try_login_with_cookies or try_login
          @is_login = true
        else
          @is_login = false
        end
      end

      def relogin
        3.times do
          if try_login
            @is_login = true
            break
          else
            @is_login = false
          end
        end
      end

      def cookies
        @weibos_spider.cookie_jar
      end

      def try_login_with_cookies
        if load_cookies
          if logined?
            logger.info "> 登录成功: 通过cookies登录"
            save_cookies
          end
        end
      end

      def try_login
        login_page = @weibos_spider.post("http://login.sina.com.cn/sso/login.php?client=ssologin.js(v1.4.15)", login_data)
        callback_url = login_page.search('script').to_s.match(/.replace\([\"\']([\w\W]*)[\"\']\)/)[1]
        after_login_page = @weibos_spider.get(callback_url)
        result_json = JSON.parse(after_login_page.body.match(/\{[\w\W]*\}/).to_s)
        if result_json["result"]
          save_cookies
          logger.info "> 登录成功: 通过账号密码登陆 #{@username}"
        else
          delete_cookies
          rescue_when_errno_is(result_json["errno"])
          logger.info "> 登录失败: #{result_json["errno"]}--#{result_json["reason"]}"
        end
      rescue Exception => e
        binding.pry
        logger.info "> 登录失败"
        logger.info e.backtrace.slice(0..5).join('\n')
      end

      private

      def rescue_when_errno_is(errno)
        case errno
        when "4040", "6202"
          self.get_proxy true
          if @login_count <= 5
            return try_login 
          end
        when "2070"
        when "2092"
        else
        end
      end

      def pre_login
        @login_info = {}
        @weibos_spider.get("http://login.sina.com.cn/sso/prelogin.php?entry=weibo&callback=sinaSSOController.preloginCallBack&su=&rsakt=mod&client=ssologin.js(v1.4.15)&_=#{Time.now.to_i.to_s}") do |page|
          @login_info = JSON.parse(page.content.match(/\{[\w\W]*\}/).to_s)
        end
      end

      def login_data
        pre_login
        @login_data = { 
          'entry'=> 'weibo', 
          'gateway'=> '1',
          'from'=> '', 
          'savestate'=> '7', 
          'userticket'=> '1',
          'ssosimplelogin'=> '1', 
          'vsnf'=> '1', 
          'su'=> encode_username,
          'service'=> 'miniblog', 
          'servertime'=> @login_info["servertime"], 
          'nonce'=> @login_info["nonce"],
          'pwencode'=> 'rsa2', 
          'rsakv'=> @login_info["rsakv"] , 
          'sp'=> encode_password,
          'encoding'=> 'UTF-8', 
          'prelt'=> '115',
          'returntype'=> 'META',
          'url'=> "http://weibo.com/ajaxlogin.php?framelogin=1&callback=parent.sinaSSOController.feedBackUrlCallBack"
        }
        save_captcha unless @login_info["pcid"].empty?
        @login_data
      end

      def save_captcha
        pcurl = "http://login.sina.com.cn/cgi/pin.php?r=#{(rand * 100000000).floor}&s=0&p=#{@login_info["pcid"]}"
        file_name = @username.sub('@', '_')
        @weibos_spider.get(pcurl).save_as("./tmp/captchas/#{file_name}.png")
        @login_data['door'] = input_captcha
      ensure
        File.delete("./tmp/captchas/#{file_name}.png") if File.exist?("./tmp/captchas/#{file_name}.png")
      end

      def input_captcha
        puts "请输入验证码:"
        door = gets 
        door.gsub("\n", '')
      end

      def encode_password(password = @password)
        login_data if @login_info.empty?
        # ----- wsse -----
        # weibo_login unless @servertime
        # pwd1 = Digest::SHA1.hexdigest password
        # pwd2 = Digest::SHA1.hexdigest pwd1
        # Digest::SHA1.hexdigest "#{pwd2}+#{@servertime}#{@nonce}"
        # ----- node -----
        # @encode_password ||= `node #{File.expand_path("../sso.js", __FILE__)} #{@login_info["pubkey"]} #{@login_info["servertime"]} #{@login_info["nonce"]} #{password}`
        # -----  rsa -----
        pwdkey = @login_info['servertime'].to_s + "\t" + @login_info['nonce'].to_s + "\n" + password
        pub = OpenSSL::PKey::RSA::new  
        pub.e = 65537 
        pub.n = OpenSSL::BN.new(@login_info['pubkey'], 16) 
        @encode_password = pub.public_encrypt(pwdkey).unpack('H*').first  
          
      end

      def encode_username(username = @username)
        Base64.strict_encode64(username.sub("@","%40"))
      end

      def save_cookies
        Dir.mkdir("tmp/cookies/") unless Dir.exist?("tmp/cookies/")
        File.open("tmp/cookies/#{encode_username}.cookie", "w") do |file|
          @weibos_spider.cookie_jar.dump_cookiestxt(file)
        end
      end

      def load_cookies
        return false unless File.exist?("tmp/cookies/#{encode_username}.cookie")
        File.open("tmp/cookies/#{encode_username}.cookie", "r") do |file|
          @weibos_spider.cookie_jar.load_cookiestxt(file)
        end
      end

      def delete_cookies
        return false unless File.exist?("tmp/cookies/#{encode_username}.cookie")
        File.delete("tmp/cookies/#{encode_username}.cookie") 
      end

      def logined?
        test_page = @weibos_spider.get("http://s.weibo.com/weibo")
        if test_page.search('a.adv_settiong')[0] && test_page.search('a.adv_settiong')[0].text == "帮助"
          true
        else
          wlr = test_page.search('script').to_s.match(/.replace\([\"\']([\w\W]*)[\"\']\)/)[1]
          test_page = @weibos_spider.get(wlr)
          test_page.search('a.adv_settiong')[0].text == "帮助"
        end
      rescue
        false
      end

    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
end