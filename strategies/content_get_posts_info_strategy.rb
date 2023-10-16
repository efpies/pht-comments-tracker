# frozen_string_literal: true

require_relative 'get_posts_info_strategy'
require_relative '../service/sheets_client'
require_relative '../model/table_post_entry'

class ContentGetPostsInfoStrategy
  include GetPostsInfoStrategy

  def initialize(sheets_client, spreadsheet_id, table, adapter)
    @sheets_client = sheets_client
    @spreadsheet_id = spreadsheet_id
    @table = table
    @adapter = adapter
  end

  def fetch_posts_info
    range = "#{@table}!A1:BZ150"

    begin
      response = @sheets_client.service.get_spreadsheet_values(@spreadsheet_id, range)
      raise "Response doesn't exist" if response.nil?

      rows = response.values

      result = {}
      if @adapter.multi_table?
        loop do
          break if rows.nil? || rows.empty?

          header_idx = rows.find_index { |row| @adapter.header?(row) }
          break if header_idx.nil?

          header = rows[header_idx].first
          rows = rows[header_idx..]
          parsed = parse_subtable(rows)
          result[header] = parsed

          rows = rows[parsed[0].size + 1..]
        end
      else
        result[@table] = parse_subtable(rows)
      end

      result
    rescue StandardError => e
      raise "Error occurred: #{e.message}"
    end
  end

  private

  def parse_subtable(rows)
    post_entries_begin_idx = rows.find_index { |row| @adapter.post?(row) }
    return [[], nil] unless post_entries_begin_idx

    post_entries = rows[post_entries_begin_idx..].take_while { |row| @adapter.post?(row) }.to_a
    return [[], nil] if post_entries.empty?

    time_table = @adapter.get_time_table rows[post_entries_begin_idx - 1]

    post_entries = post_entries.map { |post| @adapter.to_table_post_entry(post) }

    last_time = post_entries.map(&:last_comment_check_time_idx).max
    last_posts_time = time_table[last_time].to_s

    post_entries = post_entries.map do |pe|
      TablePost.new(pe.title, pe.last_comments_count, @adapter.get_post_id(pe))
    end

    [post_entries, last_posts_time]
  end
end
