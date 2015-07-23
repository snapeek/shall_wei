class WeiboUserA
  include Mongoid::Document
  field :wid               , :type => String  # 用户UID
  field :name              , :type => String  # 用户昵称
 

  def self.wa_to_csv
    CSV.open("tmp/csv/微博认证.csv", "wb") do |csv|
      csv << ["用户名", "ID", ]
      wbus = []
      all.each do |w|
        next if wbus.include? w.wid
        wbus << w.wid
        csv << [w.name, w.wid]
      end 
    end 
  end

end