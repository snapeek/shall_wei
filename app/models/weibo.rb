require File.expand_path("../../../lib/nlpir", __FILE__)
class Weibo
  include Mongoid::Document
  Nlpir::Mongoid.included self

  field :wid,            :type => String
  field :content,        :type => String
  field :user_name,      :type => String
  field :created_at,     :type => Integer
  field :rating,         :type => Float
  field :tag,            :type => String
  
  field :mid                    , :type => Integer # 微博MID
  field :uid                    , :type => String # 微博MID
  field :weibo_mid              , :type => String # 微博MID
  field :idstr                  , :type => String #  字符串型的微博ID
  field :text                   , :type => String #  微博信息内容
  field :source                 , :type => String #  微博来源
  field :geo                    , :type => Hash #  地理信息字段 详细
  field :user                   , :type => Hash #  微博作者的用户信息字段 详细
  field :retweeted_status       , :type => Hash #  被转发的原微博信息字段，当该微博为转发微博时返回 详细
  field :reposts_count          , :type => Integer # 转发数
  field :ups_count              , :type => Integer # 转发数
  field :reposts_url            , :type => String # 转发 url
  field :creposts_count         , :type => Integer, :default => 0 # 转发数
  field :comments_count         , :type => Integer # 评论数
  field :approve                , :type => Boolean, :default => false # 个人认证
  field :approve_co             , :type => Boolean, :default => false # 商业认证
  
  field :url,                     :type => String

  belongs_to :keyword
  belongs_to :weibo_user
  # belongs_to :weibo_artist
  has_many :reposts, :class_name => "Weibo", :inverse_of => :hpost
  belongs_to :hpost, :class_name => "Weibo", :inverse_of => :reposts

  scope :incrawl, ->{ where(:is_crawled => false) }
  scope :include_word, ->(_k){ where(:content => /#{_k}/)}
  scope :with_reposts, ->{ where(:hpost => nil).desc(:creposts_count)}
  scope :hot, ->{ where(:reposts_count.gt => 200).desc(:reposts_count)}

  # index({ mid: 1 })
  # index({ mid: 1 })
  index({ _id: 1 }, { unique: true, name: "_id_index" })
  index({ mid: 1 }, { name: "mid_index2" })
  index({ hpost_id: 1 }, { unique: false, name: "hpost_index" })

  validates :created_at, presence: true
  def self.woms(is_all = false)
    {
      :positive => self.where(:rating_ua.gt => 0).count,
      :negative => self.where(:rating_ua.lt => 0).count,
      :neuter => self.where(:rating_ua => 0).count
    }
  end

  def self.group_by_create
    self.desc(:created_at).group_by{|bn| bn.created_at}
  end

  def self.get_by_create_day
    _data = []
    group_by_create.each do |_k, _v|
      _data << [Time.at(_k || 0).strftime('%F'), _v.count]
    end
    _data
  end

  def to_json2
    make_nodes2(self)
  end

  def to_json_file
    File.open("public/json/#{self.tag}_#{self.id.to_s}_全部.js", "w") { |io| io.puts "var jsonData = #{make_nodes2(self).to_json} ;"
      io.puts "var myFlower = new CodeFlower(\"#visualization\", 1200, 1200);"
      io.puts "myFlower.update(jsonData);"
     }
  end

  def to_file
    File.open("public/json/#{self.tag}.rb", "w") { |io| 
      io.puts pp(make_nodes2(self))
     }
  end

  def make_nodes3(child)
    return nil if child.reposts.count == 0 
    nodes = {
      :name => (child.user_name || child.mid),
      :size => child.reposts_count,
      :size22 => child.reposts_count,
      :link => (child.reposts_url || "weibo")
    }
    nodes[:children] = child.reposts.all
                            .map { |e| make_nodes3(e) }
                            .select {|e| e }
    nodes.delete(:children) if nodes[:children].count < 1
    nodes
  end

  def make_nodes4(child, csv = nil)
    # return nil if child.reposts.count == 0
    if !csv
      csv = CSV.open("./uid_#{child.id}.csv", "w")
    end
    child.reposts.each do |rep|
      csv << [ rep.uid, rep.content,rep.reposts.count ]# if rep.reposts.count > 0
    end
    ary = child.reposts.all
               .map { |e| make_nodes4(e, csv) }
               .select {|e| e }
    ary
  end

  def node_count
    reposts_count - self.reposts.reduce(0) { |_p, v| _p + v.reposts_count } + self.reposts.count
  end

  def make_nodes_count(child, i = 1)
    hash = {"#{i}" => child.reposts.count}
    # p hash
    if i > 10
      puts "第 #{i} 级 转发: #{child.user_name} :http://weibo.com#{child.reposts_url}"
      # p child
    end
    rets = child.reposts.all.map { |e| make_nodes_count(e, i + 1) }
    rets.map do |ret|
      hash.merge!(ret) do |key, oldv, newv|
        oldv + newv
      end 
    end
    hash
  end

  def make_nodes2(child, nm = nil)
    nodes = {}
    # puts child.reposts.count
    nodes[:name] = child.user_name || child.mid
    nodes[:name] = "#{nodes[:name]}_w" if nodes[:name] == nm
    nodes[:size22] = child.reposts.count
    nodes[:size] = child.reposts.count
    nodes[:link] = child.reposts_url || "weibo"
    # puts nodes
    # binding.pry
    # return if child.reposts.count < 0
    nodes[:children] = child.reposts.all
      .map { |e| make_nodes2(e, nodes[:name]) }
    # if nodes[:children].count < child.creposts_count.to_i
    #   (child.creposts_count - nodes[:children].count).times do
    #     nodes[:children] << {
    #       :name => '转发微博',
    #       :size22 => 0,
    #       :size => 0,
    #       :link => ""
    #     }
    #   end
    # end
    # nodes[:children] = child.reposts.all
    #   .select{|e| (e.reposts_count || e.reposts.count).to_i > 0 }
    #   .map { |e| make_nodes2(e) }
    nodes.delete(:children) if nodes[:children].count < 1
    nodes
  end

  def to_json
    @nodes = []
    @links = []
    @nodes << {
      :name => "#{user_name}(#{self.reposts.count})",
      :group => 1,
      :ww => self.reposts.count
      }
    make_nodes(self, 0)
    {
      nodes: @nodes,
      links: @links
    }
  end

  def make_nodes(hwr ,i)
    hwr.reposts.each do |wr|
      if wr.reposts.count > 0
        @nodes << {
          :name => "#{wr.user_name}(#{wr.reposts.count})",
          :group => 1,
          :ww => wr.reposts.count
        }
        target = @nodes.count - 1
        @links << {
          :source => i,
          :target => target,
          :value => wr.reposts.count
        }
        make_nodes(wr, target)
      end
    end
  end

  def self.wa_to_csv
    CSV.open("tmp/csv/微博认证.csv", "wb") do |csv|
      csv << ["用户名", "ID", ]
      wbs = WeiboUser.where(:approve => true)
      wbus = []
      wbs.each do |w|
        next if wbus.include? w.uid
        wbus << w.uid
        csv << [w.user_name, w.uid]
      end 
    end 
  end

end
