require_relative 'sheets-api'
require_relative 'applogger'

class AppSettings
    attr_reader :transactionTypes, :accountsByID, :importedStatements

    def initialize(sheetsAPI)
        $logger.info "loading settings..."
        @sheetsAPI = sheetsAPI

        settingsData = sheetsAPI.loadColumns('Settings!A2:D')
        
        raise "accounts settings corrupted" unless settingsData[1].length == settingsData[2].length

        @transactionTypes = settingsData[0]
        @importedStatements = settingsData[3]

        @accountsByID = {}
        settingsData[1].each_index do |index|
            key = settingsData[1][index]

            @accountsByID[key.gsub(/\s+/, '')] = settingsData[2][index]
        end
        $logger.info "loaded settings"
    end

    def hasStatement(documentParser)
        statmentId = "#{documentParser.accont}.#{documentParser.baseDate}"
        return @importedStatements.find_index(statmentId)
    end

    def addStatement(documentParser)
        statmentId = "#{documentParser.accont}.#{documentParser.baseDate}"
        @importedStatements.push() unless hasStatement(documentParser)
    end

    def updateImportedStatements
        @sheetsAPI.saveColumn("D", @importedStatements)
    end
end