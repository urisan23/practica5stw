require 'sinatra'
require 'sinatra/activerecord'
require 'haml'
require 'rest-client'
require 'xmlsimple'

set :database, 'sqlite3:///shortened_urls.db'
set :database, 'sqlite3:///visits.db'
set :address, 'http://localhost:4567/'

class ShortenedUrl < ActiveRecord::Base
   validates_uniqueness_of :url, :custom_url, :allow_blank => true
   validates_presence_of :url
   validates_format_of :url,
      :with => %r{^(https?|ftp)://.+}i,
      :allow_blank => true,
      :message => "The URL must start with http://, https://, or ftp:// ."
end

class Visit < ActiveRecord::Base
   validates_uniqueness_of :ip
end

def set_country
   xml = RestClient.get "http://api.hostip.info/get_xml.php"
   @ip = XmlSimple.xml_in(xml.to_s, { 'ForceArray' => false })['featureMember']['Hostip']
   @visit = Visit.find_or_create_by_ip_and_country_and_abbr(@ip['ip'], @ip['countryName'], @ip['countryAbbrev'])
   @counter = Visit.count
   add_country, @countries = [], []
   add_country << Visit.select(:country).uniq
   add_country.flatten!
   add_country.each { |x| @countries << x.country}
end

before do
   set_country
end

get '/' do
   haml :index, :locals => { :u => ShortenedUrl.all, :opt => "0" }
end

post '/:type' do
  if params[:type] == "new"
    @short_url = ShortenedUrl.find_by_url(params[:url])
    if !@short_url.present?
      @short_url = ShortenedUrl.find_or_create_by_url(params[:url])
      @new = TRUE
      if @short_url.valid?
        @short_url.custom_url = settings.address+@short_url.id.to_s(36)
        @short_url.save
      else
        @exist = FALSE
      end
    else
      @exist = TRUE
    end
    haml :index, :locals => { :u => ShortenedUrl.all, :opt => "0" }
  elsif params[:type] == "custom"
    @short_url = ShortenedUrl.find_by_url(params[:url])
    if !@short_url.present?
      @short_url = ShortenedUrl.find_or_create_by_url(params[:url])
      @new = TRUE
      if @short_url.valid?
        @short_url.custom_url = settings.address+params[:custom_url]
        @short_url.save
      else
        @exist = FALSE
      end
    else
      @exist = TRUE
    end
    haml :index, :locals => { :u => ShortenedUrl.all, :opt => "0" }
  elsif params[:type] == "search"
    input = params[:url]
    if %r{^(https?|ftp)://localhost:4567}i.match(input)
      @short_url = ShortenedUrl.find_by_custom_url(params[:url])
    elsif %r{^(https?|ftp)://.+}i.match(input)
      @short_url = ShortenedUrl.find_by_url(params[:url])
    else
      @short_url = ShortenedUrl.find_by_custom_url(settings.address+params[:url])
    end
    haml :index, :locals => { :u => ShortenedUrl.all, :opt => "1" }
  end
end

get '/:chr' do
  url = ShortenedUrl.find_by_custom_url(settings.address+params[:chr])
  redirect url.url, 301
end