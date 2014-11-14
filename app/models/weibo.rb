class Weibo
  include Mongoid::Document

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
  field :favorited              , :type => Boolean # 是否已收藏，true：是，false：否
  field :truncated              , :type => Boolean # 是否被截断，true：是，false：否
  field :in_reply_to_status_id  , :type => String #  （暂未支持）回复ID
  field :in_reply_to_user_id    , :type => String #  （暂未支持）回复人UID
  field :in_reply_to_screen_name, :type => String #  （暂未支持）回复人昵称
  field :thumbnail_pic          , :type => String #  缩略图片地址，没有时不返回此字段
  field :bmiddle_pic            , :type => String #  中等尺寸图片地址，没有时不返回此字段
  field :original_pic           , :type => String #  原始图片地址，没有时不返回此字段
  field :geo                    , :type => Hash #  地理信息字段 详细
  field :user                   , :type => Hash #  微博作者的用户信息字段 详细
  field :retweeted_status       , :type => Hash #  被转发的原微博信息字段，当该微博为转发微博时返回 详细
  field :reposts_count          , :type => Integer # 转发数
  field :creposts_count         , :type => Integer, :default => 0 # 转发数
  field :comments_count         , :type => Integer # 评论数
  field :attitudes_count        , :type => Integer # 表态数
  field :mlevel                 , :type => Integer # 暂未支持
  field :visible                , :type => Hash #  微博的可见性及指定可见分组信息。该Hash中type取值，0：普通微博，1：私密微博，3：指定分组微博，4：密友微博；list_id为分组的组号
  field :pic_urls               , :type => Hash #  微博配图地址。多图时返回多图链接。无配图返回“[]”
  field :ad                     , :type => Hash # array  微博流内的推广微博ID
  
  field :repost_status          , :type => Integer, :default => 1

  field :is_artistweibo         , :type => Boolean, :default => false
  field :is_crawled             , :type => Boolean, :default => false
  field :nreposts_cache         , :type => Array, :default => []

  # field :comments_count,        :type => String
  # field :location,              :type => String
       
  # field :comments,              :type => Hash, :default => {:content => []}
  # field :cid,                   :type => String
  # field :cuser,                 :type => Hash, :default => {}
       
  field :url,                     :type => String
  # field :clicks,                :type => Hash,  :default => {}

  belongs_to :movie
  belongs_to :weibo_user
  belongs_to :weibo_artist
  has_many :reposts, :class_name => "Weibo", :inverse_of => :hpost
  belongs_to :hpost, :class_name => "Weibo", :inverse_of => :reposts

  scope :incrawl, ->{ where(:is_crawled => false) }
  scope :include_word, ->(_k){ where(:content => /#{_k}/)}
  scope :with_reposts, ->{ where(:hpost => nil).and(:creposts_count.gte => 1).desc(:creposts_count)}


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

  def get_url
    # return url if url.present?
    begin
      if weibo_mid.present?
        self.url = "http://weibo.com/#{weibo_user.wid || uid}/#{mid_to_str(weibo_mid.to_s)}"
      else
        self.url = "http://weibo.com/#{weibo_user.wid || uid}/#{mid_to_str(mid.to_s)}"
      end
    rescue Exception => e
      self.url = ""
    end
    save
    url
  end
end
