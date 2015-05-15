class Captcha
  include Mongoid::Document
  
  field :created_at,     :type => Integer, :default => Time.now.to_i
  field :code,           :type => String
  field :is_correct,     :type => Boolean
end
