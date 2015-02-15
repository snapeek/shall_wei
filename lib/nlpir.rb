# coding: utf-8
require File.expand_path("../nlpir/sad_panda", __FILE__)
require 'rbconfig'
HOST_OS = RbConfig::CONFIG['host_os']
if HOST_OS =~ /linux/i
  require File.expand_path("../nlpir/ictclas", __FILE__) 
end

$sad_panda ||= Nlpir::SadPanda.new

module Nlpir
  module Mongoid
    module ClassMethods
      case HOST_OS
      when /darwin/i
        def NLPIR_ParagraphProcess(sParagraph, bPOStagged=1)
          "已分词:" + sParagraph
        end
        alias :text_proc :NLPIR_ParagraphProcess
        
      when /linux/i
        include Nlpir::Ictclas
      end

      def after_include
        field :proced_content, :type => String
        # field :saded_content, :type => String
        field :rating_ua, :type => Float
        field :rating_us, :type => Float
        # before_create :proc_content
        scope :needed_nlpir, ->{ where(:proced_content => nil) }

      end

      def init_nlpir
        nlpir_init(File.expand_path("../../", __FILE__), UTF8_CODE)
      end      

      def latest
        self.desc(:created_at).first
      end

      def keywords(count = 100)
        init_nlpir
        str = self.all.map { |e| e.content }.join
        text_keywords(str, count, NLPIR_FALSE)
      end

      def get_new_words(filepath)
        NLPIR_NWI_Start()
        NLPIR_NWI_AddFile(filepath) #添加新词训练的文件，可反复添加
        NLPIR_NWI_Complete()        #添加文件或者训练内容结束
        puts NLPIR_NWI_GetResult().to_s #输出新词识别结果 可传入一个参数NLPIR_TRUE或NLPIR_FALSE，用于是否输出词性
        # puts NLPIR_FileProcess("a.txt","b.txt")
        NLPIR_NWI_Result2UserDict() #新词识别结果导入到用户词典
      end
    end
    module InstanceMethods
      def proc_content(force = false)
        # return if !force && proced_content.present? 
        _cl = self.class
        _cl.init_nlpir
        self.proced_content = _cl.text_proc(content)
        begin
          self.rating_ua, self.rating_us = $sad_panda.start(proced_content, rating)
          save
        rescue Exception => e
          "get a error #{e}"
        end
        # save
        # self.emotion = SadPanda.
      end

    end

    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
      receiver.after_include
    end   

  end
end