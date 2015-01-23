json.array!(@captchas) do |captcha|
  json.extract! captcha, :id
  json.url captcha_url(captcha, format: :json)
end
