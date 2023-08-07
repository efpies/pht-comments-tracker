# frozen_string_literal: true

require_relative 'check_post_strategy'

class ContentCheckPostStrategy
  include CheckPostStrategy

  def initialize(pht_client)
    @pht_client = pht_client
  end

  def check_posts(posts)
    posts.map do |post|
      check_post post
    rescue StandardError => e
      { title: post.title, error: e }
    end
  end

  private

  def check_post(post)
    url, old_count = post.url, post.comments_count
    begin
      # noinspection SpellCheckingInspection
      id = url.match(%r{/publicate/(\d+)})[1]
    rescue StandardError
      raise 'Ошибочная ссылка'
    end

    json = @pht_client.fetch_content_post(id)
    {
      title: json['title'],
      old_comments_count: old_count,
      new_comments_count: json['comments_count'],
      url: post.url
    }
  end
end
