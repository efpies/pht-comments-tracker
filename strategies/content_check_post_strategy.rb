# frozen_string_literal: true

require_relative 'check_post_strategy'

class ContentCheckPostStrategy
  include CheckPostStrategy

  def initialize(pht_client, post_service, content_uri)
    @pht_client = pht_client
    @post_service = post_service
    @content_uri = content_uri
  end

  def check_post(post)
    id = post.post_id.to_i
    old_count = post.comments_count

    post_url = "https://#{@content_uri.host}/#/publicate/#{id}?ordering=-created_at"

    post_content = @post_service.get_flow_post id
    new_comments_count = post_content['comments_count']
    if new_comments_count.zero?
      new_comments_count = 'н/к' if post_content['disable_comments']
    else
      last_comment_id = @pht_client.fetch_last_top_level_comment_id(id)
      post_url += "&comment_target_id=#{last_comment_id}" unless last_comment_id.nil?
    end

    {
      title: post_content['title'],
      old_comments_count: old_count,
      new_comments_count: new_comments_count,
      url: post_url
    }
  end
end
