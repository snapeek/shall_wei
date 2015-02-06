module WeiboUtils
  module Hacks

    def get_attr(node, attr_name)
      # logger.info "> 开始解析: #{attr_name}"
      return "" unless node.present?
      begin
        ret = node.attr(attr_name).to_s
      rescue Exception => err
        # binding.pry
        logger.fatal("> 提取出错: `#{attr_name}` #{err}")
        logger.fatal(err.backtrace.slice(0,5).join("\n"))
      end
      if block_given?
        begin
          ret = yield(ret)
        rescue Exception => err
          logger.fatal("> 执行出错: #{err}")
          logger.fatal(err.backtrace.slice(0,5).join("\n"))
        end
      end
      ret.present? ? ret : ""
    end

    def get_field(node, selector, attr_name = nil)
      ret = nil
      ret = node.search(selector).first
      ret = attr_name ? get_attr(ret, attr_name) : ret
      ret = yield(ret) if block_given?
    rescue Exception => err
      logger.fatal("> 执行出错: #{err}")
      logger.fatal(err.backtrace.slice(0,5).join("\n")) 
    ensure   
      return ret.present? ? ret : ""
    end

    def get_fields(node, selector, attr_name = nil)
      ret = nil
      ret = node.search(selector)
      ret = attr_name ? ret.map{ |e| get_attr(e, attr_name)} : ret
      ret = ret.map{|pice| yield(pice)} if block_given?
    rescue Exception => err
      logger.fatal("> 执行出错: #{err}")
      logger.fatal(err.backtrace.slice(0,5).join("\n")) 
    ensure   
      return ret.present? ? ret.select{|e| e.present? } : []
    end

    def find_fields(node, selector)
      logger.info "> 开始解析: #{selector}"
      ret = node.search(selector)
    rescue Exception => err
      logger.fatal("> 解析出错: `#{selector}` #{err}")
      logger.fatal(err.backtrace.slice(0,5).join("\n")) 
    ensure
      return ret
    end

    def get_script_html(page, ns)
      scripts = page.search("script")
      scripts = scripts.map{|script| begin JSON.parse(script.child.to_s.match(/\{[\w\W]*\}/).to_s) rescue "" end}
      if ns.is_a? Regexp
        pice = scripts.select{|script| script["ns"] =~ ns || script["pid"] =~ ns || script["domid"] =~ ns}.first
      else
        pice = scripts.select{|script| script["ns"] == ns || script["pid"] == ns || script["domid"] == ns}.first
      end

      return Nokogiri.HTML(pice["html"]) if pice
    end

    def get_json_html(page)
      joo = JSON::parse(page.body)['data']
      Nokogiri.HTML(joo["html"]) if joo
    end

    def get_config(page, attr_name = "")
      joos = page.search("script")
      joo = joos.select{|joo| joo.to_s.include?("var $CONFIG = {};")}.first.to_s
      if attr_name.present?
        return joo.match(/\$CONFIG\[\'#{attr_name}\'\][\s=\']*([\w]*)/).try("[]", 1)
      else
        joo
      end
    end

    def filtered(source, filter_sources)
      fs_flag = true
      filter_sources.each do |fs|
        fs_flag = false if source.match(fs)
      end
      fs_flag
    end

    def str_62_to_10(str62)
      i10 = 0
      i = 1
      str62.each_char do |c|
        n = str62.length - i
        i += 1
        i10 += str62keys.index(c) * (62 ** n)
      end
      i10
    end

    def str_10_to_62(int10)
      s62 = ''
      r = 0
      while int10 != 0
        s62 = str62keys[int10 % 62] + s62
        int10 = int10 / 62
      end
      s62
    end

    def mid_to_str(mid) 
      str = ''
      mid = mid.to_s.dup
      (mid.length / 7 + 1).times do |i|
        if mid.length >= 7
          num = str_10_to_62(mid.slice!(-7, 7).to_i)
        else
          num = str_10_to_62(mid.to_i)
        end
        str = num + str
      end
      str
    end

    def str_to_mid(str)
      mid = ""
      str = str.dup
      (str.length / 4 + 1).times do |i|
        offset = i < 0 ? 0 : i
        if str.length >= 4
          num = str_62_to_10(str.slice!(-4, 4))
        else
          num = str_62_to_10(str)
        end
        mid = mid.ljust(7, '0') if (offset > 0) 
        mid = num.to_s + mid
      end
      mid 
    end

    def rnd
      Time.now.to_i * 1000 + rand(1000)
    end

    def str62keys
    [
      "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
      "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
      "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"
    ]
    end

  end
end