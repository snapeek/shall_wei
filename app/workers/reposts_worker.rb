class RepostsWorker
  include Sidekiq::Worker
  sidekiq_options :retry => 3, :queue => "shallwei_#{Rails.env}".to_sym
  def perform(mid)
    weibo = WeiboCrawl.new
    weibo.repost(mid)
  end
end