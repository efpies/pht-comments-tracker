# frozen_string_literal: true

require_relative 'http_client'

class PhtClient
  def initialize(content_uri, refresh_uri, tokens)
    @client = HttpClient.new(content_uri, tokens)
    @refresh_client = HttpClient.new(refresh_uri, tokens)

    @content_uri = content_uri
    @refresh_uri = refresh_uri
    @tokens = tokens
  end

  def fetch_content_post(id)
    # noinspection SpellCheckingInspection
    uri = @content_uri.merge "api/v1/publication/retrive/#{id}/"

    retries = 5
    loop do
      response, code = @client.send_request uri, :get
      return JSON.parse(response) if code == '200'

      refresh_tokens

      retries -= 1
      raise "Error retrieving post \##{id}" if retries.zero?
    end
  end

  def refresh_tokens
    response, = @refresh_client.send_request @refresh_uri, :post, { refresh: @tokens.refresh }, auth: false

    json = JSON.parse(response)
    @tokens.update json['refresh'], json['access']
  end
end
