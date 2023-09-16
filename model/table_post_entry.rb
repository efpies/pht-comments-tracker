# frozen_string_literal: true

class TablePostEntry
  attr_accessor :date, :title, :url, :yesterday_comments_count, :time_table

  def initialize(date, title, url, yesterday_comments_count, time_table)
    @date = date
    @title = title
    @url = url
    @yesterday_comments_count = yesterday_comments_count
    @time_table = time_table || []
  end

  def last_comment_check_time_idx
    @time_table.length - 1
  end

  def last_comments_count
    return @yesterday_comments_count if @time_table.empty?

    @time_table.last.to_i
  end
end
