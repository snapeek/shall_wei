class Weibo
  include Mongoid::Document
  Nlpir::Mongoid.included self

  field :wid,            :type => String
  field :content,        :type => String
  field :user_name,      :type => String
  field :created_at,     :type => Integer
  field :rating,         :type => Float
  
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
  field :reposts_url            , :type => String # 转发 url
  field :creposts_count         , :type => Integer, :default => 0 # 转发数
  field :comments_count         , :type => Integer # 评论数
  
  field :url,                     :type => String

  belongs_to :keyword
  belongs_to :weibo_user
  # belongs_to :weibo_artist
  has_many :reposts, :class_name => "Weibo", :inverse_of => :hpost
  belongs_to :hpost, :class_name => "Weibo", :inverse_of => :reposts

  scope :incrawl, ->{ where(:is_crawled => false) }
  scope :include_word, ->(_k){ where(:content => /#{_k}/)}
  scope :with_reposts, ->{ where(:hpost => nil).and(:creposts_count.gte => 1).desc(:creposts_count)}
  scope :hot, ->{ where(:reposts_count.gt => 200).desc(:reposts_count)}

  # index({ mid: 1 })

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

end
