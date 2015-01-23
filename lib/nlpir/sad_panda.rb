module Nlpir
  class SadPanda
    @@positive = nil
    @@negative = nil
    @@level = nil

    # REG = /(?<subj>\S*((\/n\S*)|\/r\S*))?(?<pred>(^|\s)\S*((\/v\S*)|\/ude1))?(?<adverb>(^|\s)\S*\/d)?(?<embel>\s\S*\/[^wxda]\w*)*(?<adverb2>\s\S*\/d)?(?<arch>\s\S*(\/[anvbzq]\S*))+(?<punc>\s\S*(\/w\S*))?/
    REG = /
      (?<subj>\S*((\/n\S*)|\/r\S*))?
      (?<pred>(^|\s)\S*((\/v\S*)|\/ude1))?
      (?<aux>(^|\s)\S*(\/u\S*))*
      (?<adverb>(^|\s)\S*\/d)?
      (?<embel>\s\S*\/[^wxdaru]\w*)*
      (?<adverb2>\s\S*\/d)?
      (?<arch>(|\s)\S*(\/[anvbzqh]\S*))
      (?<arch2>\s\S*(\/[anvbzqhr]\S*))?
      (?<punc>\s\S*(\/w\S*))?
    /x
    ELEMENT = [:subj, :pred, :aux, :adverb, :embel, :adverb2, :arch, :arch2, :punc]
    NEGATE = /[不没别未甭莫勿休毋]/ 
    def initialize
      self.class._load_mappings if !@@level
    end

    def matched_content(content)
      matched = content.to_s.scan(REG).map do |litem|
        litem ||= []
        {
          subj: litem[0],
          pred: litem[1],
          aux: litem[2],
          adverb: litem[3],
          embel: litem[4],
          adverb2: litem[5],
          arch: litem[6],
          arch2: litem[7],
          punc: litem[8]
        }
      end
      matched
    end

    def get_word(word)
      if word
        _macthed = word.match(/(?<word>\S+)\/[a-z]+/)
        _macthed[:word] if _macthed
      end
    end

    def get_level(adverb)
      return 1 if adverb.nil?
      return 2 if @@level[:extreme].include? adverb
      return 1.6 if @@level[:very].include? adverb
      return 1.3 if @@level[:more].include? adverb
      return 1.1 if @@level[:ish].include? adverb
      return 0.7 if @@level[:insufficiently].include? adverb
      return 0.2 if @@level[:over].include? adverb
      1
    end

    def adverb_proc(matched ,emo = 1)
      str = matched[:adverb].to_s + matched[:adverb2].to_s
      # p "#{matched[:adverb]}=#{get_level(get_word(matched[:adverb]))}"
      # p "#{matched[:adverb2]}=#{get_level(get_word(matched[:adverb2]))}"
      str.to_s.scan(NEGATE).count.times{ emo *= -1 }
      emo *= get_level(get_word(matched[:adverb]))
      emo *= get_level(get_word(matched[:adverb2]))
      emo
    end

    def po_or_ne(word)
      if word.nil?
        0
      else
        return 1 if @@positive_h[:positive].include? word
        return -1 if @@negative[:negative].include? word
        return 1 if @@positive[:positive].include? word
        return -1 if @@negative_h[:negative].include? word
      end
      0
    end

    def arch_proc(matched ,emo = 1)
      arch = get_word(matched[:arch]) 
      arch2 = get_word(matched[:arch2]) 
      # p "#{matched[:arch]}+#{matched[:arch2]}"
      emo *= (po_or_ne(arch) + po_or_ne(arch2))
    end

    def punc_proc(matched ,emo = 1)
      # arch = get_word(matched[:arch]) 
      # arch2 = get_word(matched[:arch2]) 
      # emo *= (po_or_ne(arch) + po_or_ne(arch2))
      emo
    end

    def rating_proc(rating, emo = 1)
      case rating
      when 50
        return emo = (emo.abs + 1) * 1.5
      when 45
        return emo = (emo.abs + 0.5) * 1.3
      when 40
        return emo = (emo.abs + 0.5) * 1.2
      when 30, 35
        if emo > 0
          return emo = emo.abs * 0.9
        else
          return emo = emo * 1.1
        end
      when 25, 20
        return emo = (-emo.abs - 0.5) * 1.2
      when 15, 10
        return emo = (-emo.abs - 1) * 1.5
      else
        return emo
      end
    end

    def start(content, rating = nil)
      all_emo = 0
      _mc = 0
      matched_content(content).each do |matched|
        emo = adverb_proc(matched)
        p ">副词判定为 #{emo > 0}"
        emo = arch_proc(matched, emo)
        p ">定位词得分为 #{emo}"
        emo = punc_proc(matched, emo)
        emo = rating_proc(rating, emo)
        p ">评分加权为#{rating} #{emo.round(2)}"
        _mc += 1 if emo != 0
        all_emo += emo
      end
      _mc += 1 if _mc == 0
      av_emo = (all_emo / _mc).round(2)
      p ">总分#{all_emo.round(2)} 平均分#{av_emo}"
      [av_emo, all_emo.round(2)]
    end

    def self._load_mappings

      data_root = File.expand_path('../dict', __FILE__)
      
      @@positive = YAML::load(File.read("#{data_root}/tsinghua.positive.utf8.yml"))
      @@positive_h = YAML::load(File.read("#{data_root}/hownet.positive.yml"))
      @@negative = YAML::load(File.read("#{data_root}/tsinghua.negative.utf8.yml"))
      @@negative_h = YAML::load(File.read("#{data_root}/hownet.negative.yml"))
      @@level = YAML::load(File.read("#{data_root}/level.yml"))

      # while (line = word_file.gets)
      #   tokens = line.chomp.split("\t")
      #   @@mappings[tokens[1].stem] = tokens[0].to_f
      # end

      # word_file.close
    end    
  end
end