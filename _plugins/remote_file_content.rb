require 'net/http'
require 'uri'

module Jekyll

  class RemoteFileContent < Liquid::Tag
    attr_reader :url

    def initialize(tag_name, markup, tokens)
      @url = markup

      puts 'Fetching content of url: ' + url

      if @url =~ URI::regexp
        @content = fetchContent
      else
        raise 'Invalid URL passed to RemoteFileContent'
      end

      super
    end

    def render(_context)
      if @content
        @content
      else
        raise 'Something went wrong in RemoteFileContent'
      end
    end

    def fetchContent
      return %(You're in offline mode mate.\n Url: #{url}) if ENV['OFFLINE']
      Net::HTTP.get(URI.parse(URI.encode(url.strip)))
    end
  end
end

Liquid::Template.register_tag('remote_file_content', Jekyll::RemoteFileContent)
