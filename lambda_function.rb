# frozen_string_literal: true

require 'uri'
require 'json'
require 'stringio'
require 'date'
require_relative 'helpers'
require_relative 'service/db_wrapper'
require_relative 'service/tokens'
require_relative 'service/pht_client'
require_relative 'service/posts_checker'
require_relative 'service/sheets_client'
require_relative 'strategies/pht/pht_post_adapter'
require_relative 'strategies/pht/community_post_adapter'
require_relative 'strategies/pht/content_post_adapter'
require_relative 'strategies/content_get_posts_info_strategy'
require_relative 'strategies/content_check_post_strategy'
require_relative 'model/table_post'

def lambda_handler(*)
  config = {
    aws: {
      profile: ENV['AWS_PROFILE'],
      region: ENV['AWS_REGION_ID'],
      dynamodb: {
        tokens_table_name: 'phys_tokens'
      }
    },
    spreadsheets: {
      id: ENV['SPREADSHEET_ID'],
      secret_key: ENV['SPREADSHEET_SECRET_KEY']
    },
    pht: {
      content_uri: URI('https://content.pht.life/'),
      refresh_uri: URI('https://pht.life/jwt-auth/api/content/token/refresh/')
    }
  }

  Aws.config.update(profile: config[:aws][:profile], region: config[:aws][:region])

  tokens = Tokens.new DbWrapper.new(config[:aws][:dynamodb][:tokens_table_name])
  tokens.init

  pht_client = PhtClient.new config[:pht][:content_uri], config[:pht][:refresh_uri], tokens
  sheets_client = SheetsClient.new config[:spreadsheets][:secret_key]

  sections = [
    {
      key: 'new',
      get_info_strategy: ContentGetPostsInfoStrategy.new(sheets_client, config[:spreadsheets][:id], 'Новые посты', ContentPostAdapter.new),
      check_post_strategy: ContentCheckPostStrategy.new(pht_client)
    },
    {
      key: 'old',
      get_info_strategy: ContentGetPostsInfoStrategy.new(sheets_client, config[:spreadsheets][:id], 'Старые посты', ContentPostAdapter.new),
      check_post_strategy: ContentCheckPostStrategy.new(pht_client)
    },
    {
      key: 'community',
      get_info_strategy: ContentGetPostsInfoStrategy.new(sheets_client, config[:spreadsheets][:id], 'Комьюнити', CommunityPostAdapter.new),
      check_post_strategy: ContentCheckPostStrategy.new(pht_client)
    }
  ]


  response = sections.to_h do |section|
    puts "Requesting #{section[:key]}..."

    posts, last_time = section[:get_info_strategy].fetch_posts_info
    posts_checker = PostsChecker.new section[:check_post_strategy]
    posts = posts_checker.check_posts posts

    key = section[:key]
    puts "#{key}: #{last_time}"

    [key, {
      time: last_time,
      posts: posts
    }]
  end

  {
    statusCode: 200,
    headers: {
      'Access-Control-Allow-Headers' => 'Content-Type',
      'Access-Control-Allow-Origin' => '*',
      'Access-Control-Allow-Methods' => 'GET'
    },
    body: response.to_json
  }
end
