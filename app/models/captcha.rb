class Captcha
  include Mongoid::Document
  
  field :created_at,     :type => Integer, :default => Time.now.to_i
  field :code,           :type => String

  def save_as
    file_name = id.to_s
    
    File.copy("./public/captchas/#{file_name}.png", "./public/captchas/#{code}.png") if File.exist?("./public/captchas/#{file_name}.png")
  end

end
