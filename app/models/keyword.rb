require 'csv'

class Keyword
  include Mongoid::Document
  field :content          , :type => String
  field :s_content        , :type => String
  field :starttime        , :type => Integer, :default => (Time.now.at_beginning_of_day - 360.days).to_i
  field :crdtime          , :type => Integer, :default => (Time.now.at_beginning_of_day - 360.days).to_i
  field :endtime          , :type => Integer, :default => (Time.now.at_beginning_of_day - 1.days).to_i
  field :day_count        , :type => Hash,    :default => {}
  field :ori_day_count    , :type => Hash,    :default => {}
  field :news_day_count   , :type => Hash,    :default => {}
  field :is_deleted       , :type => Boolean, :default => false
  field :tags             , :type => Array,   :default => []

  has_many :kibers
  has_and_belongs_to_many :weibos
  has_and_belongs_to_many :weibo_users
  has_many :baidu_news

  scope :active, -> { where :is_deleted => false}

  def get_kiber(st, ac)
    kibers.where(:kid => "#{st}-#{ac}").first
  end

  def all_to_csv
    baidu_news_to_csv
    day_count_to_csv
    weibo_to_csv
    repost_to_csv
  end

  def w_to_csv

    CSV.open("tmp/csv/#{content}-微博-#{Time.at(starttime).strftime('%F')}-#{Time.at(endtime).strftime('%F')}.csv", "wb") do |csv|
      csv << ["用户名", "内容", "发表时间", "月", "天", "小时","转载数", "个人认证", "商业认证", "感情色彩"].map do |str| 
        str.encode('gbk', 'utf-8',{:invalid => :replace, :undef => :replace, :replace => '?'})
      end
      weibos.each do |w|
        tt = Time.at(w.created_at)
        csv << [w.user_name, w.content, tt, tt.month, tt.day, tt.hour, w.reposts_count, b2i(w.approve), b2i(w.approve_co)].map do |str|
          str.to_s.encode('gbk','utf-8',{:invalid => :replace, :undef => :replace, :replace => '?'})
        end
      end      
    end
  end

  def wa_to_csv
    csv << ["用户名", "ID", ]
    wbs = weibos.where(:approve => true)
    wbus = []
    wbs.each do |w|
      next if wbus.include w.uid
      wbus << w.uid
      csv << [w.user_name, w.uid]
    end  
  end

  def b2i(b)
    b ? 1 : 0
  end

  def w2_to_csv
    CSV.open("tmp/csv/#{content}-微博-cctv6.csv", "wb") do |csv|
      csv << ["用户名", "内容", "发表时间", "转载数", "评论数", "点赞数"]
      reposts_count = comments_count = ups_count = 0
      reposts_count_2 = comments_count_2 = ups_count_2 =0
      weibos.each do |w|
        tt = Time.at(w.created_at)
        csv << [w.user_name, w.content, tt.strftime("%F %T") , w.reposts_count, w.comments_count, w.ups_count]
        reposts_count += w.reposts_count
        comments_count += w.comments_count
        ups_count += w.ups_count
        reposts_count_2 += w.reposts_count * w.reposts_count
        comments_count_2 += w.comments_count * w.comments_count
        ups_count_2 += w.ups_count * w.ups_count
      end
        csv << ["关键词", "帖子总量", "总转载数", "总评论数" , "总点赞数", "结果"]
        csv << [content, weibos.count, reposts_count , comments_count, ups_count, 
          Math.log10(weibos.count) * (Math.sqrt(reposts_count_2/weibos.count) + Math.sqrt(comments_count_2/weibos.count) + Math.sqrt(ups_count_2/weibos.count)) / 3.0]
    end
  end


  def self.w3_to_csv
    CSV.open("tmp/csv/微博-cctv6结果.csv", "wb") do |csv|
      csv << ["关键词", "帖子总量", "总转载数", "总评论数" , "总点赞数", "ln count", "转载", "评论", "点赞", "结果"]
      Keyword.where(:is_deleted => false).each do |k|
        weibos = k.weibos
        reposts_count = comments_count = ups_count = 0
        reposts_count_2 = comments_count_2 = ups_count_2 =0
        weibos.each do |w|
          tt = Time.at(w.created_at)
          reposts_count += w.reposts_count
          comments_count += w.comments_count
          ups_count += w.ups_count
          reposts_count_2 += w.reposts_count * w.reposts_count
          comments_count_2 += w.comments_count * w.comments_count
          ups_count_2 += w.ups_count * w.ups_count
        end
          csv << [k.content, weibos.count, reposts_count , comments_count, ups_count,
            Math.log10(weibos.count), Math.sqrt(reposts_count_2/weibos.count), Math.sqrt(comments_count_2/weibos.count), Math.sqrt(ups_count_2/weibos.count),
            Math.log10(weibos.count) * (Math.sqrt(reposts_count_2/weibos.count) + Math.sqrt(comments_count_2/weibos.count) + Math.sqrt(ups_count_2/weibos.count)) / 3.0]
      end
    end
  end


  def baidu_news_to_csv
    CSV.open("tmp/csv/#{content}-百度新闻-#{Time.at(starttime).strftime('%F')}-#{Time.at(endtime).strftime('%F')}.csv", "wb") do |csv|
    # CSV.open("tmp/csv/#{content}-百度新闻-#{Time.at(starttime).strftime('%F')}-#{Time.at(endtime).strftime('%F')}.csv", "wb") do |csv|
      csv << ["标题", "摘要","地址", "来源", "日期", "相同新闻数量(百度估算)","相同新闻来源"]
      baidu_news.each do |bn|
        csv << [
          bn.title.encode("GBK", invalid: :replace, undef: :replace, replace: "?"),
          bn.summary.encode("GBK", invalid: :replace, undef: :replace, replace: "?"),
          bn.url,
          bn.source.encode("GBK", invalid: :replace, undef: :replace, replace: "?"), 
          Time.at(bn.created_at), 
          (bn.lcountents.count rescue 0) , 
          (bn.lcountents.map { |e| "#{e["source"]}(#{e["created_at"]})".encode("GBK", invalid: :replace, undef: :replace, replace: "?") }.join(' ') rescue '')]
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
    CSV.open("tmp/csv/#{content}-微博列表-#{Time.at(starttime).strftime('%F')}-#{Time.at(endtime).strftime('%F')}.csv", "wb") do |csv|
      csv << ["用户名", "内容", "发表时间", "转载数", "博主粉丝数", "博主关注数", "关注品牌媒体"]
      weibos.each do |w|
        csv << [w.user_name, w.content, Time.at(w.created_at), w.reposts_count,w.weibo_user.fans_count, w.weibo_user.follow_count, 
          w.weibo_user.follows.all.select{|wu| wu.verified_type == 1}.map(&:name).join(' ')]
      end
    end
  end

  def repost_to_csv(mid = nil)
    CSV.open("tmp/csv/#{content}-微博转发路径-#{Time.at(starttime).strftime('%F')}-#{Time.at(endtime).strftime('%F')}.csv", "wb") do |csv|
      _ws = mid.blank? ? weibos.hot : [Weibo.find_by(:mid => mid)]
      _ws.each do |w|
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
                  wwwwww.reposts.each do |wwwwwww|
                    csv << ['','','','','',wwwwwww.user_name, wwwwwww.content, Time.at(wwwwwww.created_at), wwwwwww.reposts_count]
                    wwwwwww.reposts.each do |wwwwwwww|
                      csv << ['','','','','',wwwwwwww.user_name, wwwwwwww.content, Time.at(wwwwwwww.created_at), wwwwwwww.reposts_count]
                      wwwwwwww.reposts.each do |wwwwwwwww|
                        csv << ['','','','','',wwwwwwwww.user_name, wwwwwwwww.content, Time.at(wwwwwwwww.created_at), wwwwwwwww.reposts_count]
                        wwwwwwwww.reposts.each do |wwwwwwwwww|
                          csv << ['','','','','',wwwwwwwwww.user_name, wwwwwwwwww.content, Time.at(wwwwwwwwww.created_at), wwwwwwwwww.reposts_count]
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end

end
