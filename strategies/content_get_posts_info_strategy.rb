# frozen_string_literal: true

require_relative 'get_posts_info_strategy'
require_relative '../service/sheets_client'

class ContentGetPostsInfoStrategy
  include GetPostsInfoStrategy

  CELL_IDX = {
    date: 0,
    title: 1,
    link: 2,
    prev: 3,
    time_table_begin: 4
  }.freeze
  private_constant :CELL_IDX

  def initialize(sheets_client, spreadsheet_id, table)
    @sheets_client = sheets_client
    @spreadsheet_id = spreadsheet_id
    @table = table
  end

  def fetch_posts_info
    range = "#{@table}!A1:BZ50"

    begin
      response = @sheets_client.service.get_spreadsheet_values(@spreadsheet_id, range)
      rows = response.values

      first_row = rows.find_index { |row| row[0].to_s.date? }
      return [[], nil] unless first_row

      time_table = rows[first_row - 1][CELL_IDX[:time_table_begin]..]

      posts = rows[first_row..].take_while { |row| row[0].to_s.date? }.to_a

      filled_times = posts[0][CELL_IDX[:time_table_begin]..]
      last_time = filled_times.length - 1

      last_posts_time = time_table[last_time].to_s

      posts = posts.map do |post|
        post_obj = TablePost.new
        post_obj.title = post[CELL_IDX[:title]].to_s
        post_obj.url = post[CELL_IDX[:link]].to_s
        post_obj.comments_count = (post[CELL_IDX[:time_table_begin] + last_time]).to_i
        post_obj
      end

      [posts, last_posts_time]
    rescue StandardError => e
      raise "Error occurred: #{e.message}"
    end
  end
end
