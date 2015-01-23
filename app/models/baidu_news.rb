class BaiduNews

  include Mongoid::Document

  field :title,      :type => String
  field :summary,    :type => String
  field :url,        :type => String
  field :source,     :type => String

  field :created_at, :type => Integer

  field :lcount,     :type => String
  field :lcountents, :type => Array, :default => []

  belongs_to :keyword



end