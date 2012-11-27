require 'sinatra'
require 'sinatra/activerecord'
require 'haml'
require 'rest-client'
require 'xmlsimple'


set :database, 'sqlite3:///shortened_urls.db'
set :database, 'sqlite3:///visits.db'

before '/' do
   set_country
end


def set_country
   xml = RestClient.get "http://api.hostip.info/get_xml.php"
   @ip = XmlSimple.xml_in(xml.to_s, { 'ForceArray' => false })['featureMember']['Hostip']
   @visita = Visit.find_or_create_by_ip_and_country_and_countryAbrev(@ip['ip'], @ip['countryName'], @ip['countryAbbrev'])
   @cont = Visit.count
   select_paises, @paises = [], []
   select_paises << Visit.select(:country).uniq
   select_paises.flatten!
   select_paises.each { |x| @paises << x.country}
end


class Visit < ActiveRecord::Base
   validates_uniqueness_of :ip
end  

class ShortenedUrl < ActiveRecord::Base
   validates_uniqueness_of :url, :custom_url, :allow_blank => true
   validates_presence_of :url
   validates_format_of :url,
      :with => %r{^(https?|ftp)://.+}i,
      :allow_blank => true,
      :message => "The URL must start with http://, https://, or ftp:// ."
end

get '/' do
  haml :index, :locals => { :list => ShortenedUrl.all}
end
get '/new' do
  haml :new
end
post '/new' do
  if params[:custom] == ""
    @short_url = ShortenedUrl.find_or_create_by_url(params[:url])
  else
    @short_url = ShortenedUrl.find_or_create_by_url_and_custom_url(params[:url], params[:custom])
  end
  @short_url.save
  redirect '/'
end
get '/search' do
  haml :search
end
post '/search' do
  if params[:option] == "url"
    haml :search_result, :locals => {:result => ShortenedUrl.find_by_url!(params[:url]),:opt => "url"}
  else
   begin
      search_url = ShortenedUrl.find(params[:abr].to_i(36))
   rescue
      search_url = ShortenedUrl.find_by_custom_url(params[:abr])
   end
  haml :search_result, :locals => {:result => search_url,:opt => "abr"}
  end
end
get '/:short' do |short_url|
   begin
      search_url = ShortenedUrl.find(short_url.to_i(36))
   rescue
      search_url = ShortenedUrl.find_by_custom_url(short_url)
   end
   redirect search_url.url
end
