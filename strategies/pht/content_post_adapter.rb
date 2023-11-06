# frozen_string_literal: true

class ContentPostAdapter
  include PhtPostAdapter

  CELL_IDX = {
    date: 0,
    title: 1,
    link: 2,
    yesterday_comments_count: 3,
    time_table_begin: 4
  }.freeze
  private_constant :CELL_IDX

  def initialize(content_uri)
    @content_uri = content_uri
  end

  def multi_table?
    false
  end

  def header?(_row)
    row[CELL_IDX[:link]].to_s.url?(@content_uri.host)
  end

  def post?(row)
    row[CELL_IDX[:link]].to_s.url?(@content_uri.host)
  end

  def to_table_post_entry(row)
    TablePostEntry.new(
      row[CELL_IDX[:date]].to_s,
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
    post.url.match(%r{/publicate/(\d+)})[1]
  rescue StandardError
    raise 'Ошибочная ссылка'
  end
end
