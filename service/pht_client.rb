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

    begin
      call_with_retry uri, 5, :get
    rescue StandardError
      raise "Error retrieving post \##{id}"
    end
  end

  def fetch_last_top_level_comment_id(post_id)
    uri = @content_uri.merge "api/v1/parent-comment/list/#{post_id}/?page=1&ordering=-created_at"

    begin
      response = call_with_retry uri, 5, :get
      comments = response['results']
      return nil if comments.empty?

      comments.first['pk']
    rescue StandardError
      raise "Error retrieving comments for post \##{post_id}"
    end
  end

  def refresh_tokens
    response, = @refresh_client.send_request @refresh_uri, :post, { refresh: @tokens.refresh }, auth: false

    json = JSON.parse(response)
    @tokens.update json['refresh'], json['access']
  end

  private

  def call_with_retry(uri, retries, method)
    raise 'Invalid number of retries' if retries < 1

    initial_retries = retries
    loop do
      response, code = @client.send_request uri, method
      return JSON.parse(response) if code == '200'

      refresh_tokens

      retries -= 1
      raise "Call failed after #{initial_retries} attempts" if retries.zero?
    end
  end
end
