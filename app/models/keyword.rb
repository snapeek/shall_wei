require 'csv'

class CSV

  def encode_str(*chunks)
    chunks.map { |chunk| chunk.encode(@encoding.name, invalid: :replace, undef: :replace, replace: "?") }.join('')
  end

end


class Keyword
  include Mongoid::Document
  field :content          , :type => String
  field :starttime        , :type => Integer, :default => (Time.now.at_beginning_of_day - 30.days).to_i
  field :crdtime          , :type => Integer, :default => (Time.now.at_beginning_of_day - 30.days).to_i
  field :endtime          , :type => Integer, :default => (Time.now.at_beginning_of_day - 1.days).to_i
  field :day_count        , :type => Hash,    :default => {}
  field :news_day_count   , :type => Hash,    :default => {}
  
  has_many :kibers
  has_and_belongs_to_many :weibos
  has_and_belongs_to_many :weibo_users
  has_many :baidu_news

  def get_kiber(st, ac)
    kibers.where(:kid => "#{st}-#{ac}").first
  end

  def all_to_csv
    baidu_news_to_csv
    day_count_to_csv
    weibo_to_csv
    repost_to_scv
  end



  def baidu_news_to_csv
    CSV.open("tmp/csv/#{content}-百度新闻-#{Time.at(starttime).strftime('%F')}-#{Time.at(endtime).strftime('%F')}.csv", "wb", encoding: "GBK") do |csv|
    # CSV.open("tmp/csv/#{content}-百度新闻-#{Time.at(starttime).strftime('%F')}-#{Time.at(endtime).strftime('%F')}.csv", "wb") do |csv|
      csv << ["标题", "摘要","地址", "来源", "日期", "相同新闻数量(百度估算)","相同新闻来源"]
      baidu_news.each do |bn|
        csv << [bn.title, bn.summary, bn.url, bn.source, Time.at(bn.created_at), (bn.lcountents.count rescue 0) , (bn.lcountents.map { |e| e["source"] + e["created_at"] }.join(' ') rescue '')]
      end
    end
  end

  def day_count_to_csv
    CSV.open("tmp/csv/#{content}-微博每日提及数-#{Time.at(starttime).strftime('%F')}-#{Time.at(endtime).strftime('%F')}.csv", "wb", encoding: "GBK") do |csv|
      csv << ["日期", "提及数"]
      day_count.each do |dd, dc|
        csv << [dd, dc]
      end
    end
  end

  def weibo_to_csv
    CSV.open("tmp/csv/#{content}-微博列表-#{Time.at(starttime).strftime('%F')}-#{Time.at(endtime).strftime('%F')}.csv", "wb", encoding: "GBK") do |csv|
      csv << ["用户名", "内容", "发表时间", "转载数", "博主粉丝数", "博主关注数", "关注品牌媒体"]
      weibos.each do |w|
        csv << [w.user_name, w.content, Time.at(w.created_at), w.reposts_count,w.weibo_user.fans_count, w.weibo_user.follow_count, 
          w.weibo_user.follows.all.select{|wu| wu.verified_type == 1}.map(&:name).join(' ')]
      end
    end
  end

  def repost_to_scv
    CSV.open("tmp/csv/#{content}-微博转发路径-#{Time.at(starttime).strftime('%F')}-#{Time.at(endtime).strftime('%F')}.csv", "wb", encoding: "GBK") do |csv|
      weibos.hot.each do |w|
        csv << [w.user_name, w.content, Time.at(w.created_at), w.reposts_count]
          w.reposts.each do |ww|
          csv << ['',ww.user_name, ww.content, Time.at(ww.created_at), ww.reposts_count]
          ww.reposts.each do |www|
            csv << ['', '',www.user_name, www.content, Time.at(www.created_at), www.reposts_count]
            www.reposts.each do |wwww|
              csv << ['','','',wwww.user_name, wwww.content, Time.at(wwww.created_at), wwww.reposts_count]
              wwww.reposts.each do |wwwww|
                csv << ['','','','',wwwww.user_name, wwwww.content, Time.at(wwwww.created_at), wwwww.reposts_count]
                wwwww.reposts.each do |wwwwww|
                  csv << ['','','','','',wwwwww.user_name, wwwwww.content, Time.at(wwwwww.created_at), wwwwww.reposts_count]
                end
              end
            end
          end
        end
      end
    end
  end

end
