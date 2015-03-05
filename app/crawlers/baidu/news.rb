module BaiduUtils
  module News
    module ClassMethods
      
    end
    
    module InstanceMethods

      def crawl_news(key=nil)
        key ||= Keyword.find('54ae76a76b61729cc4000000')
        # bc = BaiduCrawl.new
        # bc.news(key)
        # binding.pry
        bt = key.starttime 
        while true
          bc = BaiduCrawl.new
          bc.news(key, bt)
          bt += 1.days
          break if bt > key.endtime
        end
      end

      class BaiduCrawl

        def news(key, bt)
          @news_spider = MicroSpider.new
          @news_spider.create_action :save do |cresult|
            $a = cresult
            result = cresult[:field].inject({}){|a, b| a.merge(b)}
            i = 0
            next if result[:each_news].blank?
            result[:each_news].each do |line|
              if line[:lcount] > 0
                line[:lcountents] = (cresult[:follow][0].select{|ln| ln["entrance"] == line["ent"] }.first[:field].inject({}){|a, b| a.merge(b)}[:lnews] rescue [])
                i += 1
              end
              key.baidu_news.create(line)
            end
          end
          @news_spider.reset
          @news_spider.delay = 1
          learn_news(URI.encode(key.s_content), bt: bt, et: bt + 1.days )
          @news_spider.crawl
        end

        def learn_news(keyword ,options = {})

          @news_spider.learn do
            @crawled_pages ||= 0
            # options[:bt]   ||= kiber.created_at.to_i - 1.days
            # options[:et]   ||= kiber.created_at.to_i
            options[:bts]  = Time.at(options[:bt]).strftime("%F")
            options[:y0], options[:m0], options[:d0] = options[:bts].split('-')
            options[:ets]   = Time.at(options[:et]).strftime("%F")
            options[:y1], options[:m1], options[:d1] = options[:ets].split('-')

            site "http://news.baidu.com"

            entrance("/ns?from=news&cl=2&bt=#{options[:bt]}&y0=#{options[:y0]}&m0=#{options[:m0]}&d0=#{options[:d0]}" + 
            "&y1=#{options[:y1]}&m1=#{options[:m1]}&d1=#{options[:d1]}&et=#{options[:et]}&" +
            "q1=#{keyword}&submit=%B0%D9%B6%C8%D2%BB%CF%C2&q3=&q4=&mt=0&lm=&s=2&begin_date=#{options[:bts]}&end_date=#{options[:ets]}&tn=newsdy&ct1=1&ct=1&rn=20&q6=")

            field :body, "body" do |nb|
              binding.pry
            end

            field :day_count, "#header_top_bar .nums" do |nums|
              nums.native.text.match(/\d+/).to_s.to_i
            end

            fields :each_news, "#content_left li.result" do |news_body|
              news = {}
              news[:title] = news_body.find(".c-title").text
              news[:url] = news_body.find(".c-title a").native.attr("href")
              news[:summary] = news_body.find(".c-summary").text.gsub(news_body.find(".c-summary .c-author").text, '').split('...')[0]
              news[:created_at] = Time.parse(news_body.find(".c-summary .c-author").text).to_i
              news[:source] = news_body.find(".c-summary .c-author").text.split(' ').try('[]', 0)
              news[:lcount] = (news_body.find("a.c-more_link").native.text.match(/\d+/).to_s.to_i rescue 0)
              news[:ent] = (news_body.find("a.c-more_link").native.attr("href") rescue "non")
              news
            end

            follow "a.c-more_link" do
              fields :lnews, "#content_left li.result" do |news_body|
                news = {}
                news[:title] = news_body.find(".c-title").text
                news[:url] = news_body.find(".c-title a").native.attr("href")
                news[:summary] = news_body.find(".c-summary").text.gsub(news_body.find(".c-summary .c-author").text, '').split('...')[0]
                news[:created_at] = Time.parse(news_body.find(".c-summary .c-author").text).to_i
                news[:source] = news_body.find(".c-summary .c-author").text.split(' ').try('[]', 0)
                news
              end
            end

            save
            @is_stop = true if (@crawled_pages += 1) > 800
            p "get the page #{@crawled_pages}"
            keep_eyes_on_next_page("#page a.n:contains('下一页')")

          end
        end
      end

      
    end

    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
end