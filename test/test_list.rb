require File.join('.', File.dirname(__FILE__), *%w[.. lib encoding_wrapper.rb])

video_source1 = 'http://media.railscasts.com/assets/episodes/videos/272-markdown-with-redcarpet.mp4'
video_source2 = 'http://media.railscasts.com/assets/episodes/videos/270-authentication-in-rails-3-1.m4v'

instance = EncodingWrapper::Queue.new(6663, '9cae7f2202ad0ace51c8e4cde70dd733')

result = instance.add_media video_source1 do |f|
  f.output 'flv'
end

result2 = instance.add_media video_source2 do |f|
  f.output 'flv'
end

puts result
puts result2

puts instance.media_list