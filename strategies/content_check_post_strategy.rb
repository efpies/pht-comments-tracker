# frozen_string_literal: true

require_relative 'check_post_strategy'

class ContentCheckPostStrategy
  include CheckPostStrategy

  def initialize(pht_client)
    @pht_client = pht_client
  end

  def check_post(post)
    id = post.post_id.to_i
    old_count = post.comments_count

    post_content = @pht_client.fetch_content_post(id)
    last_comment_id = @pht_client.fetch_last_top_level_comment_id(id)

    new_comments_count = post_content['comments_count']
    new_comments_count = 'н/к' if new_comments_count.zero? && post_content['disable_comments']

    post_url = "https://content.pht.life/#/publicate/#{id}?ordering=-created_at"
    post_url += "&comment_target_id=#{last_comment_id}" if last_comment_id

    {
      title: post_content['title'],
      old_comments_count: old_count,
      new_comments_count: new_comments_count,
      url: post_url
    }
  end
end
