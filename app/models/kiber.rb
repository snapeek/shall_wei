class Kiber
  include Mongoid::Document
  field :starttime        , :type => Integer
  field :crdtime          , :type => Integer
  field :gap              , :type => Integer
  field :endtime          , :type => Integer
  field :page             , :type => Integer, :default => 1
  field :xsort            , :type => Boolean, :default => false
  field :ori              , :type => Boolean, :default => true
  field :all_count        , :type => Integer, :default => 0
  field :now_count        , :type => Integer, :default => 0
  field :status           , :type => Integer, :default => 0
  field :kid              , :type => String

  belongs_to :keyword
end
