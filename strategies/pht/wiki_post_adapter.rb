# frozen_string_literal: true

class WikiPostAdapter
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
    true
  end

  def header?(row)
    link = row[CELL_IDX[:link]].to_s
    link.url?("#{@content_uri.host}/#/listwiki")
  end

  def post?(row)
    link = row[CELL_IDX[:link]].to_s
    link.url?(@content_uri.host) && !header?(row)
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
    post.url.match(%r{/publicate/(\d+)})[1]
  rescue StandardError
    raise 'Ошибочная ссылка'
  end
end
