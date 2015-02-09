module WeiboUtils
  module DayCount
    module ClassMethods
      
    end
    
    module InstanceMethods
      def search_day_count(key)
        while key.crdtime <= key.endtime
          params = biuld_params(
            :keyword    => key.content,
            :starttime  => Time.at(key.crdtime).strftime("%F-%H"),
            :endtime    => Time.at(key.crdtime + 1.days).strftime("%F-%H"),
            :ori        => true
          )
          page = get_with_login("http://s.weibo.com/weibo/#{key.content}?page=1&#{params}")
          tweets = get_script_html(page, "pl_weibo_direct")
          tweets = page if get_field(page, ".search_num").present?
          if tweets.present?
            _c = key.day_count[Time.at(key.crdtime).strftime("%F")] = get_field(tweets, ".search_num"){|e| e.text.match(/[\d?\,]+/).to_s.gsub(',','').to_i }
          else
            _c = key.day_count[Time.at(key.crdtime).strftime("%F")] = 0
          end
          logger.info("> 成功获取: #{Time.at(key.crdtime).strftime("%F")} : #{_c}")
          key.crdtime += 1.days
          key.save
        end
      end
    end

    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
end