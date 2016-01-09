require 'pry'

require 'active_support'
require 'active_support/core_ext'
require 'faraday'
require 'oauth2'
require 'json'
require 'yaml'

site = 'http://localhost:2368/'
token = ENV['OAUTH_TOKEN']

# client_id = ''
# client_secret = ''
# client = OAuth2::Client.new(client_id, client_secret, site: site)
#
# client.auth_code.authorize_url(redirect_uri: 'http://localhost:8080/oauth2/callback')
# # => "https://example.org/oauth/authorization?response_type=code&client_id=client_id&redirect_uri=http://localhost:8080/oauth2/callback"
#
# token = client.auth_code.get_token('authorization_code_value', :redirect_uri => 'http://localhost:8080/oauth2/callback', :headers => {'Authorization' => 'Basic some_password'})
# response = token.get('/api/resource', :params => { 'query_foo' => 'bar' })
# response.class.name
# # => OAuth2::Response

conn = Faraday.new(url: site)

response = conn.get '/ghost/api/v0.1/posts/' do |request|
  request.headers['Authorization'] = "Bearer #{token}"
  request.params['include'] = 'tags,author'
  # request.params['limit'] = 25
end

payload = JSON.parse(response.body)

posts = payload.fetch("posts", [])

divider = "---\n\n"

files = posts.map do |post|
  date = Date.parse(post['published_at'])
  slug = post['slug']

  hash = {
    'title' => post['title'],
    'slug' => slug,
    'date' => date,
    'author' => post['author']['name'],
    'tags' => post['tags'].map {|tag| tag['name'] },
    'published' => post['status'] == 'published',
    'meta' => {
      'title' => post['meta_title'],
      'description' => post['meta_description']
    }
  }

  frontmatter = YAML.dump(hash)

  content = frontmatter + divider + post['markdown']
  name = "#{date}-#{slug}.md"

  [name, content]
end

files.each do |(name, content)|
  File.write(File.join('./ex', name), content)
end
