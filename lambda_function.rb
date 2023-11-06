# frozen_string_literal: true

require 'uri'
require 'json'
require 'stringio'
require 'date'
require_relative 'helpers'
require_relative 'service/db_wrapper'
require_relative 'service/tokens'
require_relative 'service/pht_client'
require_relative 'service/pht_post_service'
require_relative 'service/posts_checker'
require_relative 'service/sheets_client'
require_relative 'strategies/pht/pht_post_adapter'
require_relative 'strategies/pht/community_post_adapter'
require_relative 'strategies/pht/content_post_adapter'
require_relative 'strategies/pht/wiki_post_adapter'
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
  pht_post_service = PhtPostService.new pht_client
  pht_post_service.preload

  sections = [
    {
      key: 'new',
      get_info_strategy: ContentGetPostsInfoStrategy.new(sheets_client, config[:spreadsheets][:id], 'Новые посты', ContentPostAdapter.new),
      check_post_strategy: ContentCheckPostStrategy.new(pht_client, pht_post_service)
    },
    {
      key: 'old',
      get_info_strategy: ContentGetPostsInfoStrategy.new(sheets_client, config[:spreadsheets][:id], 'Старые посты', ContentPostAdapter.new),
      check_post_strategy: ContentCheckPostStrategy.new(pht_client, pht_post_service)
    },
    {
      key: 'wiki',
      get_info_strategy: ContentGetPostsInfoStrategy.new(sheets_client, config[:spreadsheets][:id], 'Wiki', WikiPostAdapter.new),
      check_post_strategy: ContentCheckPostStrategy.new(pht_client, pht_post_service)
    },
    {
      key: 'community',
      get_info_strategy: ContentGetPostsInfoStrategy.new(sheets_client, config[:spreadsheets][:id], 'Комьюнити', CommunityPostAdapter.new),
      check_post_strategy: ContentCheckPostStrategy.new(pht_client, pht_post_service)
    }
  ]

  response = (sections.map do |section|
    puts "Requesting #{section[:key]}..."

    posts_info = section[:get_info_strategy].fetch_posts_info
    posts_checker = PostsChecker.new section[:check_post_strategy]

    pi = posts_info.map do |key, pair|
      posts = posts_checker.check_posts pair[0]
      last_time = pair[1]

      puts "#{key}: #{last_time}"

      [key, {
        time: last_time,
        posts: posts
      }]
    end

    [section[:key], pi]
  end).to_h

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
