# frozen_string_literal: true

require 'aws-sdk-dynamodb'

class DbWrapper
  def initialize(tokens_table_name)
    @db = Aws::DynamoDB::Client.new
    @tokens_table_name = tokens_table_name
  end

  def all_tokens
    resp = @db.scan(table_name: @tokens_table_name)
    tokens = resp.items.map(&:symbolize_keys)
    tokens = [tokens.find { |item| item[:id] == 'access' } || {}, tokens.find { |item| item[:id] == 'refresh' } || {}]
    tokens.map { |t| t[:token] }
  rescue Aws::DynamoDB::Errors::ServiceError => e
    puts "Error reading items: #{e.message}"
    raise
  end

  def put_tokens(refresh, access)
    params = {
      request_items: {
        @tokens_table_name => [
          {
            put_request: {
              item: {
                id: 'access',
                token: access,
              }
            }
          },
          {
            put_request: {
              item: {
                id: 'refresh',
                token: refresh,
              }
            }
          }
        ]
      }
    }

    begin
      @db.batch_write_item(params)
    rescue Aws::DynamoDB::Errors::ServiceError => e
      puts "Error adding item: #{e.message}"
    end
  end
end
