# frozen_string_literal: true

require 'net/http'

class HttpClient
  def initialize(base_uri, tokens)
    @client = Net::HTTP.new(base_uri.host || 'localhost', base_uri.port)
    @client.use_ssl = true

    @tokens = tokens
  end

  def send_request(uri, method = :get, body = nil, auth: true)
    request = build_request uri, method, body, auth: auth
    response = @client.request(request)
    sio = StringIO.new(response.body)
    [sio.read, response.code]
  end

  private

  def build_request(uri, method = :get, body = nil, auth: true)
    case method
    when :get
      request = Net::HTTP::Get.new(uri)
    when :post
      request = Net::HTTP::Post.new(uri)
    else
      raise "Unknown method #{method}"
    end

    request['Accept'] = '*/*'
    request['Accept-Language'] = 'ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7'
    request['Authorization'] = "Secret #{@tokens.access}" if auth
    request['Connection'] = 'keep-alive'
    request['DNT'] = '1'
    request['Referer'] = 'https://content.pht.life/'
    request['Sec-Fetch-Dest'] = 'empty'
    request['Sec-Fetch-Mode'] = 'cors'
    request['Sec-Fetch-Site'] = 'same-site'
    request['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36'
    request['sec-ch-ua'] = '"Not.A/Brand";v="8", "Chromium";v="114", "Google Chrome";v="114"'
    request['sec-ch-ua-mobile'] = '?0'
    request['sec-ch-ua-platform'] = '"macOS"'

    if body
      request['Content-Type'] = 'application/json'
      request.body = body.to_json
    end

    request
  end
end
