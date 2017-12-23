require 'bundler/setup'

require_relative 'sheets-api'
require_relative 'appsettings'

spreadsheetId = "1LkmAnd7vkW1AhwbgEOd1W-xmPiYJluaLzI1MDURFeFc";

api = SheetsAPI.new(spreadsheetId)
settings = AppSettings.new(api)