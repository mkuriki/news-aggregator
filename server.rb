require 'sinatra'
require 'pry'
require 'csv'
require 'uri'

set :public_folder, File.join(File.dirname(__FILE__), "public")

def create_article_array
  temp = []
  CSV.foreach('articles.csv', headers: true) do |a|
    temp << a.to_hash
  end
  temp
end

get '/' do
  @title = "Home"
  erb :index
end

get '/articles' do
  @title = "View All"
  @articles = create_article_array.reverse!
  erb :articles
end

get '/articles/new' do
  @errors = {}
  @title = "Post New Article"
  erb :article_new
end

post '/articles/new_post' do
  @errors = {}
  @errors[:title] = 'Title' if params['title'] == ''

  @errors[:url] =
    if params['url'] == ''
      'URL'
    else
      uri = URI.parse(params['url'])
      if !uri.kind_of?(URI::HTTP)
        'Invalid URL'
      else
        @articles = []
        @articles = create_article_array
        dupe = @articles.find { |a| a['url'] == uri.to_s }
        'Duplicate URL (article already posted)' if !dupe.nil?
      end
    end

  @errors[:description] =
    if params['description'] == ''
      'Description'
    elsif params['description'].length < 20
      'Description (too short)'
    end

  @errors.delete_if { |k, v| v.nil? }

  if @errors.any?
    @title = "Post New Article"
    erb :article_new
  else
    CSV.open('articles.csv', 'a') do |csv|
      csv << [ params['title'], params['url'], params['description'] ]
    end
    redirect '/articles'
  end
end
