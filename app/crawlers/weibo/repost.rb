$list = []
$debug = false
module WeiboUtils
  module Repost
    module ClassMethods
      
    end
    
    module InstanceMethods

      def getr
        a = [
            ["权力的游戏1" , "http://weibo.com/1788911247/DspC7moTj"],
            ["权力的游戏2" , "http://weibo.com/1222062284/Dw6nYvFbo"],
            ["权力的游戏3" , "http://weibo.com/1788911247/Dqzw1z9e2"],
            ["信号1"    , "http://weibo.com/1444865141/DtIwbiKPS"],
            ["信号2"    , "http://weibo.com/5506111978/DtNB56KHB"],
            ["我的奇妙男友1", "http://weibo.com/5583906018/DuiYoByUR"],
            ["我的奇妙男友2", "http://weibo.com/1742121542/DvlKpoho0"],
            ["约吧大明星1" , "http://weibo.com/2591595652/DvmciBiMD"],
            ["约吧大明星2" , "http://weibo.com/2416080157/DwnvgoIs9"],
            ["约吧大明星3" , "http://weibo.com/2416080157/DvjJA9WQP"],
            ["拜托了冰箱1" , "http://weibo.com/5888671022/Dw8dktjQ8"],
            ["拜托了冰箱2" , "http://weibo.com/5687925374/Dxc3QjIln"],
            ["你正常吗1"  , "http://weibo.com/5061558889/DvO9qekIG"],
            ["你正常吗2"  , "http://weibo.com/1713926427/DwIT67NaN"],
        ]
        errors = []
        a.each {|aa| 
          begin
            get_repost_from(aa[1], aa[0])
          rescue Exception => e
            errors << e
          end
        }
        errors
      end

      def get_repost_from(url, tag = "", page_num)
        page = get_with_login(url)
        # user = get_script_html(page, /Pl_Official_RightOwner/)
        page = get_script_html(page, /Pl_Official_WeiboDetail/)
        w = {}
        w[:wid] = w[:mid] = str_to_mid(url.split('/').last)
        w[:user_name] = get_field(page, '.WB_info .S_txt1').text
        w[:text] = get_field(page, '.WB_detail .WB_text').text
        w[:created_at] = get_field(page, 'div.WB_from.S_txt2>a'){|a| Time.parse(a.attr('title')).to_i }
        w[:reposts_count] = get_field(page, '.WB_feed_handle .WB_handle'){|e| e.text.to_s.match(/转发[\s]*(\d+)/).try("[]", 1).to_i}
        # weibo = w[:mid] ? Weibo.find_or_create_by(:mid => w[:mid]) : Weibo.new(w)
        w[:tag] = tag
        weibo = Weibo.find_or_create_by(:mid => w[:mid])
        weibo.update(w)
        # weibo.mid = 3996477955456118
        # weibo.mid = 3988770720075729
        weibo.wid = weibo.mid
        weibo.save
        repost(weibo.mid, false, page_num)
      end

      def repost(mid, force = false, page_num = nil, max_page = nil)
        host_weibo = Weibo.find_by(:mid => mid)
        if page_num 
          nextpage = "id=#{mid}&page=#{page_num}"
        else
          nextpage = "id=#{mid}"
        end
        i = 0
        while nextpage.present?
          i += 1 
          sleep(1)
          url = "http://weibo.com/aj/v6/mblog/info/big?ajwvr=6&#{nextpage}"
          # url = "http://weibo.com/aj/v6/mblog/info/big?ajwvr=6&#{nextpage}&__rnd=#{rnd}"
          if $list.include? url
            logger.info("> 此 url 已访问过: #{url}.")
            return 
          end
          p url
          $list << url
          page = get_with_login(url, true)
          # logger.info("> 获取成功: #{url}.")
          page = JSON.parse(page.body)
          if page["code"].to_s == "100000"
            # if page["data"]["count"].to_i == 0
            #   binding.pry
            #   return 
            # end
            repost_pices = Nokogiri.HTML(page["data"]["html"])
          else
            raise "AjaxGetError"
          end
          get_fields(repost_pices, ".list_li") do |post_pice|
            w = get_repost(post_pice)
            save_repost(w, host_weibo, force)
            if w[:reposts_count] > 0
              logger.info("> 准备递归: 下方有转发 #{w[:reposts_count]} 条.")
              repost(w[:mid], true) 
            end
          end
          binding.pry if $debug
          nextpage = get_field(repost_pices, ".WB_cardpage .next span", 'action-data')
          if !force && !nextpage.present?
            repost(mid, force = false, page_num.to_i + i + 1)
            binding.pry
          end
          pn = page["data"]["page"]["pagenum"]
          return if pn > 1 && pn >= page["data"]["page"]["totalpage"]
        end
      rescue Exception => err
        logger.fatal("> 获取出错: ")
        logger.fatal(err)
        logger.fatal(err.backtrace.slice(0,5).join("\n"))
      end

      def get_repost(post_pice)
        w = {}
        w[:user_name]  = get_field(post_pice, '.WB_face>a>img', 'alt')
        w[:uid]        = get_field(post_pice, '.WB_face>a>img', 'usercard'){|e| e.match(/\d{6,13}/).to_s }
        w[:mid]        = get_attr(post_pice, 'mid')
        w[:content]    = get_field(post_pice, '.WB_text>span'){ |e| e.text.gsub(/[\t\n]/,'')}
        w[:created_at] = get_field(post_pice, '.WB_from'){|e| Time.parse(e.text).to_i rescue 0}
        w[:reposts_count] = get_field(post_pice, '.WB_func .WB_handle li[2]'){|e| e.text.to_s.match(/转发[\s]*(\d+)/).try("[]", 1).to_i}
        unless w[:mid]
          mid_pice = get_fields(post_pice, '.WB_func .WB_handle .line').last
          w[:mid] = get_field(mid_pice, "a", 'action-data') {|e| e.match(/mid=(\d*)/)[1]}
        end
        w[:reposts_url]= "/#{w[:uid]}/#{mid_to_str(w[:mid])}?type=repost"
        w
      rescue Exception => err
        logger.fatal("> 提取出错: ")
        logger.fatal(err)
        logger.fatal(err.backtrace.slice(0,5).join("\n"))
      end

      def save_repost(w, host_weibo, force)
        if w[:mid]
          weibo = Weibo.where(:mid => w[:mid]).first
          # logger.info("> 存在微博: #{weibo.content} #{force ? "并强行改写" : "跳过"}") if weibo
          # return weibo if weibo && !force
        end
        weibo ||= Weibo.create(w)
        # weibo.save
        # wu = WeiboUser.create(
        #   :wid => w[:uid],
        #   :name => w[:user_name]
        # )
        # logger.info("> 转发已保存: (#{host_weibo.reposts.count})#{host_weibo.mid} << (#{weibo.hpost.blank?})#{weibo.mid} .")
        host_weibo.reposts << weibo if force || weibo.hpost.blank?
        # wu.weibos << weibo
        weibo.save
        host_weibo.save
        # wu.save
      rescue Exception => err
        logger.fatal("> 保存出错: ")
        logger.fatal(err)
        logger.fatal(err.backtrace.slice(0,5).join("\n"))
      end
    end

    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
end