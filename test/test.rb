require File.join('.', File.dirname(__FILE__), *%w[.. lib encoding_wrapper.rb])

video_source = 'http://media.railscasts.com/assets/episodes/videos/272-markdown-with-redcarpet.mp4'

instance = EncodingWrapper::Queue.new(6663, '9cae7f2202ad0ace51c8e4cde70dd733')

result = instance.add_media video_source do |f|
  f.output 'flv'
end
puts result

sleep 2

puts instance.request_status(result[:media_id])

sleep 2

puts instance.cancel_media(result[:media_id])
