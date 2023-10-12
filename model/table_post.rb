# frozen_string_literal: true

class TablePost
  attr_accessor :title, :comments_count, :post_id

  def initialize(title, comments_count, post_id)
    @title = title
    @comments_count = comments_count
    @post_id = post_id
  end

  def to_s
    "#{@title} (#{@comments_count} comments), id: #{@post_id}"
  end
end
