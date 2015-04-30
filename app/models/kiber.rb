class Kiber
  include Mongoid::Document
  include Mongoid::Timestamps
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
  field :mark             , :type => String
  field :is_active        , :type => Boolean, :default => false
  field :kid              , :type => String

  belongs_to :keyword
end
