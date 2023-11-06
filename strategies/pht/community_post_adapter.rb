# frozen_string_literal: true

class CommunityPostAdapter
  include PhtPostAdapter

  CELL_IDX = {
    title: 0,
    link: 1,
    yesterday_comments_count: 2,
    time_table_begin: 3
  }.freeze
  private_constant :CELL_IDX

  def initialize(content_uri)
    @content_uri = content_uri
  end

  def multi_table?
    false
  end

  def header?(row)
    row[CELL_IDX[:link]].to_s.url?(@content_uri.host)
  end

  def post?(row)
    row[CELL_IDX[:link]].to_s.url?(@content_uri.host)
  end

  def to_table_post_entry(row)
    TablePostEntry.new(
      '0001-01-01',
      row[CELL_IDX[:title]].to_s,
      row[CELL_IDX[:link]].to_s,
      row[CELL_IDX[:yesterday_comments_count]].to_i,
      row[CELL_IDX[:time_table_begin]..]
    )
  end

  def get_time_table(row)
    row[CELL_IDX[:time_table_begin]..] || []
  end

  def get_post_id(post)
    # noinspection SpellCheckingInspection
    post.url.match(%r{/topic/(\d+)})[1]
  rescue StandardError
    raise 'Ошибочная ссылка'
  end
end
