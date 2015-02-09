class DayCountWorker
  include Sidekiq::Worker
  sidekiq_options :retry => 3, :queue => "shallwei_#{Rails.env}".to_sym
  def perform(key_id)
    weibo = WeiboCrawl.new
    key = Keyword.find(key_id)
    weibo.search_day_count(key)
  end
end