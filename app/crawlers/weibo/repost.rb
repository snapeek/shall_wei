module WeiboUtils
  module Repost
    module ClassMethods
      
    end
    
    module InstanceMethods
      def get_repost_from(url)
        page = get_with_login(url)
        page = get_script_html(page, /Pl_Official_WeiboDetail/)
        w = {}
        w[:wid] = w[:mid] = str_to_mid(url.split('/').last)
        w[:text] = get_field(page, '.WB_detail .WB_text').text
        w[:created_at] = get_field(page, 'div.WB_from.S_txt2>a'){|a| Time.parse(a.attr('title')).to_i }
        weibo = w[:mid] ? Weibo.find_or_create_by(:mid => w[:mid]) : Weibo.new
        weibo = weibo.update(w)
        weibo.save
        repost(weibo.mid)
      end

      def repost(mid)
        host_weibo = Weibo.find_by(:mid => mid)
        nextpage = "id=#{mid}&filter=0"
        while nextpage.present?
          url = "http://weibo.com/aj/v6/mblog/info/big?ajwvr=6&#{nextpage}&__rnd=#{rnd}"
          page = get_with_login(url, true)
          logger.info("> 获取成功: 当前参数是 #{nextpage}.")
          page = JSON.parse(page.body)
          if page["code"].to_s == "100000"
            return if page["data"]["count"].to_i == 0
            repost_pices = Nokogiri.HTML(page["data"]["html"])
          else
            raise "AjaxGetError"
          end
          get_fields(repost_pices, ".list_li") do |post_pice|
            w = get_repost(post_pice)
            save_repost(w, host_weibo)
            logger.info("> 准备递归: 下方有转发 #{w[:reposts_count]} 条.")
            repost(w[:mid])
          end
          nextpage = get_field(repost_pices, ".WB_cardpage .next span", 'action-data')
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
        w[:reposts_count] = get_field(post_pice, '.WB_func .WB_handle'){|e| e.text.to_s.match(/转发[\s]*(\d+)/).try("[]", 1).to_i}
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

      def save_repost(w, host_weibo)
        weibo = Weibo.where(:mid => w[:mid]).fisrt
        return weibo if weibo
        weibo = Weibo.create(w)
        weibo.save
        # wu = WeiboUser.create(
        #   :wid => w[:uid],
        #   :name => w[:user_name]
        # )
        logger.info("> 准备转入: (#{host_weibo.reposts.count})#{host_weibo.mid} << (#{weibo.hpost.blank?})#{weibo.mid} .")
        host_weibo.reposts << weibo if weibo.hpost.blank?
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