class BaiduNews

  include Mongoid::Document

  field :title,      :type => String
  field :category,   :type => String
  field :from,       :type => String
  field :summary,    :type => String
  field :url,        :type => String
  field :content,    :type => String
  field :source,     :type => String
  field :source_url, :type => String

  field :photos,     :type => Array, :default =>[]
  field :videos,     :type => Array, :default =>[]

  field :cmt_count,  :type => Integer
  field :act_lcount, :type => Integer

  field :cralwed_at, :type => Integer
  field :created_at, :type => Integer

  belongs_to :from

end