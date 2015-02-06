class WeiboSearchWorker
  include Sidekiq::Worker
  sidekiq_options :retry => 3, :queue => "shallwei_#{Rails.env}".to_sym

  def perform(kid)
    weibo = WeiboCrawl.new
    k = Kiber.find(kid)

    while true
      break if k.crdtime > k.endtime
      starttime = Time.at(k.crdtime).strftime("%F-%H")
      endtime = Time.at(k.crdtime + k.gap.hours).strftime("%F-%H")
      weibo.search(
        keyword: k.keyword.content, 
        page: k.page , 
        starttime: starttime, 
        endtime: endtime, 
        xsort: false, 
        ori: true,
        kid: kid)
      k.crdtime += k.gap.hours
      k.page = 1
      break if k.crdtime > k.endtime
    end
    k.status = k.status | 4
    k.save

    # HardWorker.perform_async('bob', 5)
    # http://weibo.com/aj/v6/mblog/info/big?ajwvr=6&id=3736949468252602&filter=hot&__rnd=1420691773404
    # id=3736949468252602&max_id=3736950459034504&filter=hot&page=2 action-data
  end
end