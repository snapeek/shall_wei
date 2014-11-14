module WeiboUtils
  module ClassMethods
    
  end
  
  module InstanceMethods

    def get_with_login(url, is_ajax = false)
      # @weibos_spider.
      
    end
  end
  
  def self.included(receiver)
    receiver.extend         ClassMethods
    receiver.send :include, InstanceMethods
  end
end