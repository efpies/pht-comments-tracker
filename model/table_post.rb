# frozen_string_literal: true

class TablePost
  attr_accessor :title, :comments_count, :url

  def initialize(title, comments_count, url)
    @title = title
    @comments_count = comments_count
    @url = url
  end
end
