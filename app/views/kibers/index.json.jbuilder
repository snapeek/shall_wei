json.array!(@kibers) do |kiber|
  json.extract! kiber, :id
  json.url kiber_url(kiber, format: :json)
end
