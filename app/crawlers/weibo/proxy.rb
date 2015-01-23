module WeiboUtils
  module Proxy
    module ClassMethods
      
    end
    
    module InstanceMethods
      def set_proxy
        prx = @account.proxy
        if !( prx && prx.confirm)
          prx = ::Proxy.get_one
          @account.proxy = prx
          @account.save
        end
        @weibos_spider.set_proxy(prx.ip, prx.port)
      end
    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
end