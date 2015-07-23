module WeiboUtils
  module Auser
    module ClassMethods
      
    end

    module InstanceMethods
      def auser(url = nil, options = {})
        url ||= "http://d.weibo.com/1087030002_892_1003_0"
        options[:page] ||= 1
        options[:page].upto(100) do |current_page|
          puts "正在爬取 第#{current_page} 页"
          user_page = weibos_spider.tget("#{url}?page=#{current_page}#Pl_Core_F4RightUserList__4")
          users_pice = get_script_html(user_page, "Pl_Core_F4RightUserList__4")
          weibousers = get_fields(users_pice, 'ul.follow_list li .mod_pic img') do |limg|
            [
              get_attr(limg, 'alt'),
              get_attr(limg, 'usercard') { |li| li.sub('id=', '')  }
            ]
          end
          weibousers.each do |wu|
            WeiboUserA.find_or_create_by(name: wu[0], wid: wu[1])
          end
          total_page = get_fields(users_pice, ".W_pages .page"){|e| e.text.to_s.to_i }.max
          sleep([3,4,5,6,7].sample)
          break if current_page + 1 > total_page.to_i
        end
      end
    end

    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end    
  end
end