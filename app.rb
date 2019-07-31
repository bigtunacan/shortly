require 'sucker_punch'
require 'sinatra'
require 'faraday'
require 'sequel'
require 'byebug'
require 'pg'

DB = Sequel.connect(ENV['DATABASE_URL'] || 'postgres://localhost/mydb')

class UrlCrawler
  include SuckerPunch::Job

  # This updates the url mapping with the page's title.
  #
  # For the purposes of this exercise you could end up
  # with title's like "301 moved" etc... due to invalid/malformed
  # URIs.  A real world application would need a better method
  # of handling this.
  def perform(data)
    title = ''
    res = Faraday.get(data[:url])
    substr = res.body.scan(/<title>.+<\/title>/i)
    if substr.length > 0
      substr = substr[0].downcase
      title = substr.gsub("<title>", "").gsub("</title>", "")
    else
      title = 'No Title Located'
    end
    DB[:url_mappings].where(id: data[:id]).update(title: title)
  end
end

post '/url' do
  request.body.rewind
  url = ''
  if request.content_type == "application/json"
    data = JSON.parse request.body.read
    url = data['url']
  elsif request.content_type == "application/x-www-form-urlencoded"
    data = request.body.read
    data = data.split('=')
    if data[0] == 'url' && data.length == 2
      url = data[1]
    else
      halt 404
    end
  else
    halt 404
  end

  if url
    short_key = DB[:short_keys].where(used: false).limit(1).first
    new_full_url = "#{request.env["HTTP_HOST"]}/#{short_key[:short_key]}"

    DB[:short_keys].where(id: short_key[:id]).update(used: true)
    id = DB[:url_mappings].insert(url: url, short_keys_id: short_key[:id])

    # Crawls the URL for the page title in the background
    UrlCrawler.perform_async({url: url, id: id})

    { short_url: new_full_url }.to_json
  end

end

get '/top' do
  top_urls = []
  top_url_mappings = DB[:url_mappings].order(Sequel.desc(:request_count)).limit(100)
  top_url_mappings.each do |url|
    top_urls << { url: url[:url], title: url[:title] }
  end
  top_urls.to_json
end

# Use the Sinatra "catch-all" route to redirect
# the short code to the "real" URI
get '/*' do
  short_key = request.env['REQUEST_PATH'][1..request.env['REQUEST_PATH'].length-1]
  short_key = DB[:short_keys].where(short_key: short_key).limit(1).first
  url = DB[:url_mappings].where(short_keys_id: [short_key[:id]]).limit(1).first
  request_count = url[:request_count]
  request_count += 1
  DB[:url_mappings].where(id: url[:id]).update(request_count: request_count)
  redirect to(url[:url])
end
