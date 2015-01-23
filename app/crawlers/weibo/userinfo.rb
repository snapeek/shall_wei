module WeiboUtils
  module UserInfo
    module ClassMethods
      
    end
    
    module InstanceMethods
      def userinfo(uid)
        wuser = WeiboUser.find_or_create_by(:wid => uid)
        url = "http://weibo.com/p/100505#{uid}/info?mod=pedit_more"

        logger.info("> 正在采集: 用户 #{wuser.name} 的详细信息.")
        page = get_with_login(url)
         
        wuser[:luid] = get_config page, 'page_id'

        v_fans = get_script_html(page, /Pl_Core_T8CustomTriColumn/)
        v_info = get_script_html(page, /Pl_Official_PersonalInfo/)
        v_prv  = get_script_html(page, /Pl_Official_RightGrowNew/)
        v_head = get_script_html(page, /Pl_Official_Headerv6__1/)

        wuser[:follow_count], wuser[:fans_count], wuser[:weibo_count] = get_fields(v_fans, ".S_line1 strong"){|e| e.text}
        wuser[:approve] = get_field(v_info, ".verify").present? if v_prv

        get_fields(v_info, 'li') do |v_li|
          v_li_h = v_li.text.gsub(/\s/, '').split('：')
          case v_li_h[0]
          when "昵称"     then wuser[:name] ||= v_li_h[1]
          when "所在地"   then wuser[:location] = v_li.search('.pt_detail').text
          when "性别"     then wuser[:gender] = v_li_h[1] == "女" ? "f" : "m"
          when "生日"     then wuser[:birth] = v_li_h[1]
          when "标签"     then wuser[:tags] = v_li.text.split('：').last.gsub(/\s+/, ' ')
          when "公司"     then wuser[:company] = v_li_h[1]
          when "血型"     then wuser[:blood_type] = v_li_h[1]
          when "感情状况" then wuser[:marriage] = v_li_h[1]
          when "注册时间" then wuser[:created_at] = v_li_h[1]
          when "大学"    then wuser[:university] = v_li_h[1]
          when "高中"    then wuser[:mschool] = v_li_h[1]
          end
        end
        wuser[:profile_image_url] = get_field(v_head, ".photo_wrap img", "src") 
        wuser[:profile_image_url] = get_field(v_head, ".cover_wrap", "style"){|a| a.match(/\(([\s\S]*)\)/)[1].to_s} unless wuser[:profile_image_url]
        wuser.crawl_status = wuser.crawl_status | 2
        wuser.save
      end
    end

    def follower(uid)
      page_number = 0
      return unless wuser = WeiboUser.where(:wid => uid).first
      max_page_number = (wuser.follow_count % 20.0).ceil
      max_page_number = 5 if max_page_number > 5 
      while page_number < max_page_number
        page_number += 1
        logger.info("> 正在采集: 用户 #{wuser.name} 的关注信息 page(#{page_number}).")
        page = get_with_login("http://weibo.com/#{uid}/follow?page=#{page_number}#place") 
        _followers = get_script_html(page, "pl.content.followTab.index")
        get_fields(_followers, 'li.follow_item') do |fol|
          wu = {}
          wu[:name] = get_field(fol, '.mod_pic>a', 'title')
          wu[:wid] = get_field(fol, '.mod_pic>a>img', 'usercard'){|e| e.match(/\d{6,13}/).to_s }
          user = WeiboUser.find_or_create_by(wid: wu[:wid])
          wuser.follows << user
          user.update wu
          wuser.save
        end
      end
      wuser.crawl_status = wuser.crawl_status | 4
      wuser.save
    end

    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
end