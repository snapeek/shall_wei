module WeiboUtils
  module Proxy
    module ClassMethods
      
    end
    
    module InstanceMethods
      def get_proxy
        
      end
    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
end