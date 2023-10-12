# frozen_string_literal: true

require_relative 'get_posts_info_strategy'
require_relative '../service/sheets_client'
require_relative '../model/table_post_entry'

class ContentGetPostsInfoStrategy
  include GetPostsInfoStrategy

  CELL_IDX = {
    date: 0,
    title: 1,
    link: 2,
    yesterday_comments_count: 3,
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
      raise "Response doesn't exist" if response.nil?

      rows = response.values

      post_entries_begin_idx = rows.find_index { |row| row[CELL_IDX[:link]].to_s.url? }
      return [[], nil] unless post_entries_begin_idx

      post_entries = rows[post_entries_begin_idx..].take_while { |row| row[CELL_IDX[:link]].to_s.url? }.to_a
      return [[], nil] if post_entries.empty?

      time_table = rows[post_entries_begin_idx - 1][CELL_IDX[:time_table_begin]..]

      post_entries = post_entries.map do |post|
        TablePostEntry.new(
          post[CELL_IDX[:date]].to_s,
          post[CELL_IDX[:title]].to_s,
          post[CELL_IDX[:link]].to_s,
          post[CELL_IDX[:yesterday_comments_count]].to_i,
          post[CELL_IDX[:time_table_begin]..]
        )
      end

      last_time = post_entries.map(&:last_comment_check_time_idx).max
      last_posts_time = time_table[last_time].to_s

      post_entries = post_entries.map do |pe|
        begin
          # noinspection SpellCheckingInspection
          id = pe.url.match(%r{/publicate/(\d+)})[1]
        rescue StandardError
          raise 'Ошибочная ссылка'
        end

        TablePost.new(pe.title, pe.last_comments_count, id)
      end

      [post_entries, last_posts_time]
    rescue StandardError => e
      raise "Error occurred: #{e.message}"
    end
  end
end
