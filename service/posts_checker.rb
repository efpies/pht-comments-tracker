# frozen_string_literal: true

class PostsChecker
  def initialize(check_post_strategy)
    @check_post_strategy = check_post_strategy
  end

  def check_posts(posts)
    posts.map do |post|
      raise 'Post ID is not set' if post.post_id.nil?

      @check_post_strategy.check_post post
    rescue StandardError => e
      { title: post.title, error: e }
    end
  end
end
