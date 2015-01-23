module KeywordsHelper
  def st(_t)
    Time.at(_t).strftime("%F")
  end

  def can_count(real_count)
    real_count > 24000 ? 24000 : real_count
  end

  
end
