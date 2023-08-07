# frozen_string_literal: true

require 'google/apis/sheets_v4'
require 'googleauth'

class SheetsClient
  attr_reader :service

  def initialize(service_key)
    @service = Google::Apis::SheetsV4::SheetsService.new
    @service.client_options.application_name = 'Your Application Name'
    @service.key = service_key
  end
end
