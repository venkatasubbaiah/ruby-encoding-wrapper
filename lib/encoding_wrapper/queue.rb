require 'rubygems'
require 'uri'
require 'net/http'
require 'nokogiri'
require 'rexml/document'


module EncodingWrapper

  module Actions
    ADD_MEDIA       = "AddMedia"
    UPDATE_MEDIA    = "UpdateMedia"
    CANCEL_MEDIA    = "CancelMedia"
    GET_STATUS      = "GetStatus"
    GET_MEDIA_LIST  = "GetMediaList"
    GET_MEDIA_INFO  = "GetMediaInfo"
  end


  module StatusType
    NEW             = "New"
    WAITING         = "Waiting for encoder"
    PROCESSING      = "Processing"
    SAVING          = "Saving"
    FINISHED        = "Finished"
    ERROR           = "Error"
    DELETED         = "Deleted"
    DOWNLOADING_NEW = "DownloadingNew"
  end

  class Queue
    attr_reader :user_id, :user_key


    def initialize(user_id=nil, user_key=nil, url=nil)
      @user_id = user_id
      @user_key = user_key
      @url = url || 'http://manage.encoding.com/'
    end


      # format fields:
      #   output (required):
      #     flv, fl9, wmv, 3gp, mp4, m4v, ipod, iphone, ipad, android, ogg, webm, appletv, psp, zune, mp3, wma,
      #     m4a, thumbnail, image,
      #     mpeg2 (just experimental feature, please use with care, feedback is welcome),
      #     iphone_stream, ipad_stream, muxer
    def request_encoding(action=nil, source=nil, notify: {})
      # :size, :bitrate, :audio_bitrate, :audio_sample_rate,
      # :audio_channels_number, :framerate, :two_pass, :cbr,
      # :deinterlacing, :destination, :add_meta

      xml = Nokogiri::XML::Builder.new do |q|
        q.query {
          q.userid  @user_id
          q.userkey @user_key
          q.action  action
          q.source  source
          q.notify(notify[:url]) if notify.key?(:url)
          q.notify_encoding_errors(notify[:encoding_errors]) if notify.key?(:encoding_errors)
          q.notify_upload(notify[:upload]) if notify.key(:upload)
          q.notify_upload_extended(notify[:upload_extended]) if notify.key(:upload_extended)
          q.notify_live_start(notify[:live_start]) if notify.key(:live_start)
          q.qc_notify(notify[:qc]) if notify.key(:qc)
          q.format  { |f| yield f }
        }
      end.to_xml

      response = request_send(xml)

      if response[:errors].present?
        message = response[:errors]
      else
        message = response[:message]
        media_id = response[:xml].css('MediaID').text
      end

      {
        :message => message,
        :media_id => media_id
      }

    end


    def request_status(media_id)
      xml = Nokogiri::XML::Builder.new do |q|
        q.query {
          q.userid    @user_id
          q.userkey   @user_key
          q.action    EncodingWrapper::Actions::GET_STATUS
          q.mediaid   media_id
        }
      end.to_xml

      response = request_send(xml)

      response[:status] = false
      response[:progress] = false

      if response[:errors].length == 0
        response[:status] = response[:xml].css('status').first.text
        response[:progress] = response[:xml].css('progress').text.to_i

        # there is a bug where the progress reports
        # as 100% if the status is 'Waiting for encoder'
        if (response[:status] == EncodingWrapper::StatusType::WAITING)
          response[:progress] = 0
        end
      end

      response
    end


    def cancel_media(media_id)
      xml = Nokogiri::XML::Builder.new do |q|
        q.query {
          q.userid    @user_id
          q.userkey   @user_key
          q.action    EncodingWrapper::Actions::CANCEL_MEDIA
          q.mediaid   media_id
        }
      end.to_xml

      response = request_send(xml)
    end


      # format fields:
      #   output (required):
      #     flv, fl9, wmv, 3gp, mp4, m4v, ipod, iphone, ipad, android, ogg, webm, appletv, psp, zune, mp3, wma,
      #     m4a, thumbnail, image,
      #     mpeg2 (just experimental feature, please use with care, feedback is welcome),
      #     iphone_stream, ipad_stream, muxer
    def add_media(source=nil, notify: {})
      # :size, :bitrate, :audio_bitrate, :audio_sample_rate,
      # :audio_channels_number, :framerate, :two_pass, :cbr,
      # :deinterlacing, :destination, :add_meta

      xml = Nokogiri::XML::Builder.new do |q|
        q.query {
          q.userid  @user_id
          q.userkey @user_key
          q.action  EncodingWrapper::Actions::ADD_MEDIA
          q.source  source
          q.notify(notify[:url]) if notify.key?(:url)
          q.notify_encoding_errors(notify[:encoding_errors]) if notify.key?(:encoding_errors)
          q.notify_upload(notify[:upload]) if notify.key(:upload)
          q.notify_upload_extended(notify[:upload_extended]) if notify.key(:upload_extended)
          q.notify_live_start(notify[:live_start]) if notify.key(:live_start)
          q.qc_notify(notify[:qc]) if notify.key(:qc)
          q.format  { |f| yield f }
        }
      end.to_xml

      response = request_send(xml)

      response[:media_id] = false

      if response[:errors].length == 0
        response[:media_id] = response[:xml].css('MediaID').text
      end

      response
    end

    def media_add(source=nil, notify:{})
      add_media(source, notify: notify)
    end

    def media_cancel(media_id)
      cancel_media(media_id)
    end

    def media_status(media_id)
      request_status(media_id)
    end

    def media_list
      xml = Nokogiri::XML::Builder.new do |q|
        q.query {
          q.userid    @user_id
          q.userkey   @user_key
          q.action    EncodingWrapper::Actions::GET_MEDIA_LIST
        }
      end.to_xml

      response = request_send(xml)

      response[:list] = []

      media_list = response[:xml].css('response media')

      media_list.each do |media|
        obj = {}

        fields = media.css('*')
        fields.each do |field|
          obj[field.name.to_sym] = field.text
        end

        response[:list] << obj
      end

      response
    end


    private

    def build_query(action)
      query = Nokogiri::XML::Builder.new do |q|
        q.query {
          q.userid  @user_id
          q.userkey @user_key
          q.action  action
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

      output = {:errors => [], :status => false, :xml => '', :message => ''}
      output[:xml] = Nokogiri::XML(response.body)

      errors = output[:xml].css('errors error')
      if errors.length != 0
        errors.each { |error| output[:errors] << error.text }
      else
        output[:status] = true
      end

      response_messages = output[:xml].css('response message')
      if response_messages.length == 1
        output[:message] = response_messages.text
      end

      output
    end

  end
end
