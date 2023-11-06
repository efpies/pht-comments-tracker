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

  def load_fix_page
    puts 'Fetching fixed pages'

    uri = @content_uri.merge 'api/v1/publication/feed/fix-list/?&flows=29&feed_group=physical_transformation'

    begin
      response = call_with_retry uri, 5, :get
      Hash[response.map { |p| [p['id'], p] }]
    rescue StandardError
      raise "Error retrieving fixed pages \##{id}"
    end
  end

  def load_pages(list, from, count = nil, sublist = nil)
    puts "[#{list}] Fetching #{count || 'all'} pages from #{from}"

    posts = []
    page = from
    to = count.nil? ? nil : from + count - 1
    loop do
      break if !to.nil? && (page > to)

      response = load_page list, sublist, page

      break if response.nil?

      pagination = response['pagination']
      posts += response['results']

      break unless pagination['has_next']

      page += 1
    end

    posts.to_h { |post| [post['id'], post] }
  end

  def load_page(list, sublist, page)
    puts "[#{list}#{"/#{sublist}" unless sublist.nil?}] Fetching page \##{page}"

    uri = @content_uri.merge "api/v1/publication/#{list}/list/#{"#{sublist}/" unless sublist.nil?}?page=#{page}&flows=29&feed_group=physical_transformation&visible_page_count=100"

    begin
      call_with_retry uri, 5, :get
    rescue StandardError
      raise "Error retrieving pages \##{id}"
    end
  end

  def fetch_content_post(id)
    puts "Fetching post \##{id}"

    # noinspection SpellCheckingInspection
    uri = @content_uri.merge "api/v1/publication/retrive/#{id}/"

    begin
      call_with_retry uri, 5, :get
    rescue StandardError
      raise "Error retrieving post \##{id}"
    end
  end

  def fetch_last_top_level_comment_id(post_id)
    puts "Fetching last comment for post \##{post_id}"

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

  def load_wiki_ids
    puts 'Loading wikis'

    uri = @content_uri.merge 'api/v1/wiki/page/list/'

    begin
      response = call_with_retry uri, 5, :get
      response.map { |w| w['pk'] }
    rescue StandardError
      raise 'Error loading wikis'
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
      return nil if code == '404'

      refresh_tokens

      retries -= 1
      raise "Call failed after #{initial_retries} attempts" if retries.zero?
    end
  end
end
