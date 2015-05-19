module WeiboUtils
  module Search
    module ClassMethods
      
    end
    
    module InstanceMethods
      def biuld_params(options)
        options.each do |k, v|
          options.delete(k) if v.nil? || v.to_s.empty?
        end
        options_buffer = ""
        if options[:msgtype]
          options_buffer += "scope="
          case options[:msgtype]
          when 1
            options_buffer += "ori=custom::"
          end
        end
        if options[:ori]
          options_buffer += "&scope=ori"
        else
          options_buffer += "&typeall=1"
        end        
        if options[:xsort]
          options_buffer += "&xsort=hot"
        end
        if options[:starttime]
          options_buffer += "&timescope=custom:#{Time.at(options[:starttime]).strftime("%F-%H")}:#{Time.at(options[:endtime]).strftime("%F-%H")}"
        end      
        # if options[:searchtype]
        #   case options[:searchtype]
        #   when 0

        #   when 1

        #   when 8
        #     options_buffer += "timescope=custom:#{options[:starttime]}:#{options[:endtime]}"
        #   end
        # end
        unless options[:province].nil? || options[:province].empty?
          options_buffer += "&region=custom:#{options[:province]}:#{options[:city] || 1000}"
        end
        options_buffer
      end

      def search(options = {
          # :page         => 1
          # :keyword      => keyword,
          # :sorttype     => sorttype,
          # :search_type  => search_type,
          # :searchtime   => searchtime,
          # :msgtype      => msgtype,
          # :search_type  => search_type,
          # :starttime    => starttime
          # :endtime      => endtime,
          # :province     => province,
          # :city         => city,
          # :filter_sources => filter_sources
        })
        @kiber = Kiber.find(options[:kid]) if options[:kid]
        @keyword = @kiber.keyword
        result = {:weibos => []}
        params = biuld_params(options)
        logger.info("> 搜索结果: 当前关键字为#{options[:keyword]}, 其余参数为 #{params}")
        options[:now_count] = 0
        options[:page].upto(50) do |current_page|
          options[:page] = current_page
          result[:weibos].clear
          logger.info "> 搜索结果: 第 #{current_page} 页,"
          search_page = get_with_login("http://s.weibo.com/weibo/#{URI.encode(options[:keyword])}&suball=#{current_page}#{params}&Refer=g")
          # weibos_pice = get_script_html(search_page, "pl_weibo_direct")
          weibos_pice = get_script_html(search_page, "pl_weibo_direct")
          weibos_pice = get_field(search_page, "#pl_weibo_direct") if weibos_pice.blank?
          ac = 0
          while weibos_pice.blank? && ac < 3
            ac += 1
            @current_weibo_spider.xproxy
            search_page = get_with_login("http://s.weibo.com/weibo/#{URI.encode(options[:keyword])}&suball=#{current_page}#{params}&Refer=g")
            weibos_pice = get_script_html(search_page, "pl_weibo_direct")
            weibos_pice = get_field(search_page, "#pl_weibo_direct") if weibos_pice.blank?
          end
          result[:total_num] = get_field(weibos_pice, ".search_num"){|e| e.text.to_s.match(/[\d?\,]+/).to_s.gsub(',','').to_i }
          # options[:total_num] ||= result[:total_num]
          break if result[:total_num].to_i == 0
          # result[:weibos] += get_fields(weibos_pice, '.search_feed feed_lists') {|weibo_pice| get_weibo(weibo_pice) }

          result[:weibos] += get_fields(weibos_pice, '.search_feed>div>div>div.S_bg2') {|weibo_pice| get_weibo(weibo_pice) }
          options[:weibo_now_count] = result[:weibos].count
          save_status(options)
          save_weibos(result[:weibos])
          break unless get_field(weibos_pice, ".W_pages"){ |a| a.text.try('include?',"下一页")}
        end
      rescue Exception => err
        # binding.pry
        logger.fatal("> 搜索出错: #{err}")
        logger.fatal(err.backtrace.slice(0,5).join("\n"))
        # save_status(options)
      ensure
        return result
      end


        def all_count(options)
          result = {}
          options[:ori] = true
          params = biuld_params(options)
          search_page = get_with_login("http://s.weibo.com/weibo/#{URI.encode(options[:keyword])}&suball=1#{params}&Refer=g")
          weibos_pice = get_script_html(search_page, "pl_weibo_direct")
          weibos_pice = get_field(search_page, "#pl_weibo_direct") if weibos_pice.blank?
          ac = 0
          while weibos_pice.blank? && ac < 3
            ac += 1
            @current_weibo_spider.xproxy
            search_page = get_with_login("http://s.weibo.com/weibo/#{URI.encode(options[:keyword])}&suball=1#{params}&Refer=g")
            weibos_pice = get_script_html(search_page, "pl_weibo_direct")
            weibos_pice = get_field(search_page, "#pl_weibo_direct") if weibos_pice.blank?
          end
          result[:total_num_ori] = get_field(weibos_pice, ".search_num"){|e| e.text.to_s.match(/[\d?\,]+/).to_s.gsub(',','').to_i }
          options[:ori] = false
          params = biuld_params(options)
          search_page = get_with_login("http://s.weibo.com/weibo/#{URI.encode(options[:keyword])}&suball=1#{params}&Refer=g")
          ac = 0
          search_page = get_with_login("http://s.weibo.com/weibo/#{URI.encode(options[:keyword])}&suball=1#{params}&Refer=g")
          weibos_pice = get_script_html(search_page, "pl_weibo_direct")
          weibos_pice = get_field(search_page, "#pl_weibo_direct") if weibos_pice.blank?
        while weibos_pice.blank? && ac < 3
          ac += 1
          @current_weibo_spider.xproxy
          search_page = get_with_login("http://s.weibo.com/weibo/#{URI.encode(options[:keyword])}&suball=1#{params}&Refer=g")
          weibos_pice = get_script_html(search_page, "pl_weibo_direct")
          weibos_pice = get_field(search_page, "#pl_weibo_direct") if weibos_pice.blank?
        end
        result[:total_num_all] = get_field(weibos_pice, ".search_num"){|e| e.text.to_s.match(/[\d?\,]+/).to_s.gsub(',','').to_i }
        logger.info("> 搜索结果: #{result[:total_num_all]} ---- #{result[:total_num_ori]}")
        return result
      rescue Exception => err
        logger.fatal("> 搜索出错: #{err}")
        logger.fatal(err.backtrace.slice(0,5).join("\n"))
        return result
      end
      
      private

      # def load_status
      #   Dir["#{File.dirname(__FILE__)}/weibo/*.rb"].each {|path| require path} 
      # end

      def save_status(options)
        @search_options = options
        return unless @kiber
        @kiber.page = options[:page]
        # @kiber.all_count = options[:total_num]
        @kiber.now_count += options[:weibo_now_count]
        @kiber.status = @kiber.status | 2
        @kiber.save
        # Dir.mkdir("tmp/search_status/") unless Dir.exist?("tmp/search_status/")
        # File.open("tmp/search_status/#{options[:keyword]}.yaml", "wb") {|f| YAML.dump(@search_options, f) }
      end

      def save_weibos(weibos)
        weibos.each do |w|
          u = WeiboUser.find_or_create_by(:wid => w[:uid])
          u.crawl_status = 1 unless u.crawl_status > 0 
          u.name ||= w[:user_name]
          ww = @keyword.weibos.create(w)
          # ww = @keyword.weibos.find_or_create_by(:mid => w[:mid])
          # ww.update(w)
          u.weibos << ww
          @keyword.weibos << ww
          @keyword.save
          u.save
          if u.crawl_status & 2 != 2
            # userinfo(w[:uid]) rescue logger.fatal("> 采集出错: 用户 #{u.name} 的用户信息采集错误.")
          end
          if u.crawl_status & 4 != 4
            # follower(w[:uid]) rescue logger.fatal("> 采集出错: 用户 #{u.name} 的关注信息采集错误. ")
          end
        end
      end

      def rescue_search
        search @search_options
      end

      def get_weibo(weibo_pice)
        w = {}
        w[:mid]           = get_field(weibo_pice, '.feed_from .W_textb', 'suda-data').match(/:(\d+)/).try('[]', 1)
        w[:content]       = get_field(weibo_pice, '.comment_txt'){ |e| e.text.gsub(/[\t\n]/,'')}
        w[:user_name]     = get_field(weibo_pice, '.face>a', 'title')
        w[:created_at]    = get_field(weibo_pice, '.feed_from>.W_textb'){|e| Time.parse(e.attr('title')).to_i rescue 0}
        # w[:source]        = get_field(weibo_pice, '.info>a'){|e| e.text}
        w[:uid]           = get_field(weibo_pice, '.face>a>img', 'usercard'){|e| e.match(/\d{6,13}/).to_s }

        w[:approve]       = get_field(weibo_pice, '.feed_content a.approve').present?
        w[:approve_co]    = get_field(weibo_pice, '.feed_content a.approve_co').present?
        # w[:name]          = get_field(weibo_pice, '.feed_content>a.W_texta', 'nick-name')
        # w[:mid]           ||= get_field(weibo_pice, '.content>p.info>span>a', 'action-data'){|e| e.match(/mid=(\d*)/)[1]}
        w[:reposts_count] = get_field(weibo_pice, '.feed_action_info'){|e| e.text.to_s.match(/转发(\d+)/).try("[]", 1).to_i}
        w[:comments_count]= get_field(weibo_pice, '.feed_action_info'){|e| e.text.to_s.match(/评论(\d+)/).try("[]", 1).to_i}
        w[:ups_count]     = get_field(weibo_pice, '.feed_action_info .W_ico12'){|e| e.parent.text.to_i}

        w[:reposts_url]   = "/#{w[:uid]}/#{mid_to_str(w[:mid])}?type=repost"
      ensure
        return w
      end    
    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
end