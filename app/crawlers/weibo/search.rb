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
        if options[:xsort]
          options_buffer += "&xsort=hot"
        end
        if options[:starttime]
          options_buffer += "&timescope=custom:#{options[:starttime]}:#{options[:endtime]}"
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
        result = {:weibos => []}
        params = biuld_params(options)
        logger.info("当前关键字为#{options[:keyword]}, 其余参数为 #{params}")
        options[:page].upto(50) do |current_page|
          options[:page] = current_page
          logger.info ">搜索结果: 第 #{current_page} 页,"
          search_page = get_with_login("http://s.weibo.com/wb/#{options[:keyword]}?page=#{current_page}#{params}&Refer=g")
          # weibos_pice = get_script_html(search_page, "pl_weibo_direct")
          weibos_pice = get_script_html(search_page, "pl_wb_feedlist")
          result[:total_num] ||= get_field(weibos_pice, ".search_num"){|e| e.text.match(/[\d?\,]+/).to_s.gsub(',','').to_i }
          break if result[:total_num].to_i == 0
         
          result[:weibos] += get_fields(weibos_pice, '.search_feed .feed_lists') {|weibo_pice| get_weibo(weibo_pice) }
          break unless get_field(weibos_pice, ".W_pages").text.try('include?',"下一页")
          save_status(options)
        end
      rescue Exception => e
        save_status(options)
        binding.pry
      ensure
        save_weibos(result[:weibos])
        return result
      end
      
      private

      # def load_status
      #   Dir["#{File.dirname(__FILE__)}/weibo/*.rb"].each {|path| require path} 
      # end

      def save_status(options)
        @search_options = options
        Dir.mkdir("tmp/search_status/") unless Dir.exist?("tmp/search_status/")
        File.open("tmp/search_status/#{options[:keyword]}.yaml", "wb") {|f| YAML.dump(@search_options, f) }
      end

      def save_weibos(weibos)
        weibos.each do |w|
          Weibo.create(w)
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
        w[:created_at]    = get_field(weibo_pice, '.feed_from>.W_textb'){|e| Time.parse(e).to_i rescue 0}
        # w[:source]        = get_field(weibo_pice, '.info>a'){|e| e.text}
        w[:uid]           = get_field(weibo_pice, '.face>a>img', 'usercard'){|e| e.match(/\d{6,13}/).to_s }
        # w[:mid]           ||= get_field(weibo_pice, '.content>p.info>span>a', 'action-data'){|e| e.match(/mid=(\d*)/)[1]}
        # w[:reposts_count] = get_field(weibo_pice, '.info>span'){|e| e.text.to_s.match(/转发\((\d+)/)[1]}
        # if (_wc = get_field(weibo_pice, '.comment .info>span a:eq(1)')).present?
        #   w[:content]     = get_field(weibo_pice, '.comment dt em'){|e| e.to_s.gsub(/<[^>]*>/, '')}
        #   w[:reposts_url] = get_attr(_wc, 'href')
        #   w[:mid]         = str_to_mid(w[:reposts_url].match(/\/(\w+)\?/)[1])
        #   w[:uid]         = w[:reposts_url].match(/\d{6,13}/).to_s
        # end
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