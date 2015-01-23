module WeiboUtils
  module Brand
    module ClassMethods
      
    end
    
    module InstanceMethods
      def brand_list(ism = false)
        m = ism ? "media" : "brand"
        brands_page = jget("http://verified.e.weibo.com/#{m}")
        # nav_barMain
        brands_pice = get_script_html(brands_page, "pl_home_leftNav")
        brands_pice = get_field(brands_pice, ".nav_barMain")
        brands_pnode = get_fields(brands_pice, ".nav_aItem")
        brands_pnode.each{|ba| save_brand_pnode(ba, ism)}
      end

      def save_brand_pnode(ba, ism = false)
        bp = get_field(ba, ".a_outer a") 
        # return if ::Brand.where(name: bp.text.to_s.gsub('>', '')).exists?
        bpn = ::Brand.find_or_create_by(name: bp.text.to_s.gsub('>', ''))
        bpn.update(
          url: bp.attr("href"), 
          brand_id: bp.attr("href").match(/rand\/(\d+)/).try("[]", 1)
        ) 
        get_fields(ba, ".item_child li a") do |bc|
          logger.info "> 搜索结果: 正在保存 #{bc.text}."
          bcn = ::Brand.find_or_create_by(name: bc.text)
          bcn.update(
            url: bc.attr("href"), 
            brand_id: bc.attr("href").match(/rand\/(\d+)/).try("[]", 1)) 
          bpn.cnodes << bcn
          get_brand(bcn, ism)
          bcn.save
        end
        bpn.save
      end

      def get_brand(bcn, ism = false)
        page = 1
        srt = 'a'
        while srt <= 'z'
          while page < 30
            bc_page = jget("http://verified.e.weibo.com#{bcn.url}?rt=0&srt=4&letter=#{srt}&page=#{page}")
            if bc_page.blank?
              bc_page = jget("http://verified.e.weibo.com#{bcn.url}?rt=0&srt=4&letter=#{srt}&page=#{page}")
            end
            next if bc_page.blank?
            break unless save_brand_page(bc_page, bcn, ism)
            page += 1        
          end
          srt = srt.next
        end
      rescue Exception => err
        logger.fatal "> 搜索出错: #{bcn.name} 下级品牌保存出错."
        logger.fatal(err)
        logger.fatal(err.backtrace.slice(0,5).join("\n")) 
      end

      def save_brand_page(bc_page, bcn, ism)
        brands_pice = get_script_html(bc_page, "pl_category_recommandFinal")
        get_fields(brands_pice, ".index_list .detail li .select_user") { |brand| save_brand(brand, bcn, ism) }
        get_field(brands_pice, ".W_pages .W_btn_a"){|a| a.text.to_s.include?("下一页")}.present?
      rescue
        logger.fatal "> 搜索出错: #{bcn.name} 下级品牌保存出错."
        logger.fatal(err)
        logger.fatal(err.backtrace.slice(0,5).join("\n"))       
      end

      def save_brand(brand, bcn, ism = false)
        _brand = {
          name: get_field(brand, ">a"){|a| a.text},
          wid: get_field(brand, ".head_img input"){|ipt| ipt.attr("value")},
          verified_type: ism ? 2 : 1
        }
        wu = WeiboUser.find_or_create_by(:wid => _brand[:wid])
        bcn.weibo_brands << wu
        wu.update(_brand)
      rescue Exception => err
        logger.fatal "> 搜索出错: #{_brand[:name]} 保存出错."
        logger.fatal(err)
        logger.fatal(err.backtrace.slice(0,5).join("\n")) 
      end
    end
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
end