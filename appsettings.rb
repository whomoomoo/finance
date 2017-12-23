require_relative 'sheets-api'

class AppSettings
    @transactionTypes
    @accountsByID

    def initialize(sheetsAPI)
        puts "loading settings..."
        @sheetsAPI = sheetsAPI

        settingsData = sheetsAPI.loadColumns('Settings!A2:C')
        
        raise "accounts settings corrupted" unless settingsData[1].length == settingsData[2].length

        @transactionTypes = settingsData[0]

        @accountsByID = {}
        settingsData[1].each_index do |index|
            key = settingsData[1][index]

            @accountsByID[key.gsub(/\s+/, '')] = settingsData[2][index]
        end
        puts "loaded settings"
    end
end