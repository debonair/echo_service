require 'bundler'
Bundler.setup
require 'sinatra/base'
require 'nokogiri'
require 'builder'

class EchoService < Sinatra::Base
  set :root, File.dirname(__FILE__)

  def initialize(*args)
    @xsd = Nokogiri::XML::Schema(File.read("#{File.dirname(__FILE__)}/public/echo_service.xsd"))
    @xslt = Nokogiri::XSLT(File.read("#{File.dirname(__FILE__)}/lib/soap_body.xslt"))
    super
  end

  post '/echo_service' do
    begin
      request.body.rewind
      doc = Nokogiri::XML(request.body.read)
      soap_message = @xslt.transform(doc)
      errors = @xsd.validate(soap_message).map{|e| e.message}.join(", ")
      raise errors unless errors == ""
      message = doc.root.at_xpath('//echo:Message/text()', 'echo' => 'http://www.without-brains.net/echo')
      builder(:echo_response, :locals => {:message => message})
    rescue Exception => e
      halt(500, builder(:fault, :locals => {:fault_string => e.message}))
    end
  end
end
