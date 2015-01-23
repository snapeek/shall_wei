json.array!(@keywords) do |keyword|
  json.extract! keyword, :id, :content, :starttime, :endtime, :day_count
  json.url keyword_url(keyword, format: :json)
end
