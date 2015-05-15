json.array!(@captchas) do |captcha|
  json.extract! captcha, :id
  json.cid :id
  json.img_url captcha_url(captcha, format: :png)
  json.url captcha_url(captcha, format: :json)
end
