require 'rubygems'
require 'uri'
require 'net/http'
require 'builder' #TODO: remove it, Nokogiri is better solution
require 'nokogiri'
require 'rexml/document'


module EncodingWrapper

  module Actions
    ADD_MEDIA = "AddMedia"
    GET_STATUS = "GetStatus"
    CANCEL_MEDIA = "CancelMedia"
  end


  module StatusType
    NEW = "New"
    WAITING = "Waiting for encoder"
    PROCESSING = "Processing"
    SAVING = "Saving"
    FINISHED = "Finished"
    ERROR = "Error"
  end

  class Queue
    attr_reader :user_id, :user_key

    API_ENDPOINT = 'http://manage.encoding.com/'


    def initialize(user_id=nil, user_key=nil)
      @user_id = user_id
      @user_key = user_key
    end


    def request_encoding(action=nil, source=nil, notify_url=nil)
      xml = Builder::XmlMarkup.new :indent => 2
      xml.instruct! 
      xml.query do |q|
        q.userid @user_id
        q.userkey @user_key
        q.action action
        q.source source
        q.notify notify_url
        q.format { |f| yield f }
      end

      request_send(xml.target!)
    end


    def request_status(media_id)
      xml = Builder::XmlMarkup.new :indent => 2
      xml.instruct!
      xml.query do |q|
        q.userid    @user_id
        q.userkey   @user_key
        q.action    EncodingWrapper::Actions::GET_STATUS
        q.mediaid   media_id
      end

      response = request_send(xml.target!)
    end


    def cancel_media(media_id)
      xml = Builder::XmlMarkup.new :indent => 2
      xml.instruct!
      xml.query do |q|
        q.userid    @user_id
        q.userkey   @user_key
        q.action    EncodingWrapper::Actions::CANCEL_MEDIA
        q.mediaid   media_id
      end

      response = request_send(xml.target!)
    end


    private

    def build_query(action)
      query = Nokogiri::XML::Builder.new do |q|
        q.query {
          q.userid @user_id
          q.userkey @user_key
          q.action action
          yield q if block_given?
        }
      end.to_xml
    end


    def request_send(xml)
      url = URI.parse(@url)
      request = Net::HTTP::Post.new(url.path)
      request.form_data = { :xml => xml }
      response = Net::HTTP.new(url.host, url.port).start { |http|
        http.request(request)
      }
    end

  end
end