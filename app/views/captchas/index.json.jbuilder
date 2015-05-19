json.array!(@captchas) do |captcha|
  json.cid captcha.id.to_s
  json.img_url captcha_url(captcha, format: :png)
end
