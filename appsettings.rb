require_relative 'sheets-api'
require_relative 'applogger'
require_relative 'accounttypes'

class AppSettings
    attr_reader :transactionTypes, :accountsByNum, :importedStatements, :accountTypeByName, :accountNumByID

    def initialize(sheetsAPI)
        $logger.info "loading settings..."
        @sheetsAPI = sheetsAPI

        settingsData = sheetsAPI.loadColumns('Settings!A2:E')
        
        raise "accounts settings corrupted" unless settingsData[1].length == settingsData[2].length
        raise "accounts settings corrupted" unless settingsData[1].length == settingsData[3].length

        @transactionTypes = settingsData[0]
        @importedStatements = settingsData[4]

        @accountsByID = {}
        @accountTypeByName = {}
        @accountNumByID = {}
        settingsData[1].each_index do |index|
            key = settingsData[1][index]
            type = AccountTypes.const_get(settingsData[3][index].upcase)

            raise "unknown account type #{settingsData[3][index].upcase}" if type.nil?

            @accountsByID[key.gsub(/\s+/, '')] = settingsData[2][index]
            @accountTypeByName[settingsData[2][index].strip] = type
            @accountNumByID[settingsData[2][index]] = key.gsub(/\s+/, '')
        end
        $logger.info "loaded settings"
    end

    def hasStatement(documentParser)
        return @importedStatements.find_index(documentParser.Id)
    end

    def addStatement(documentParser)
        @importedStatements.push() unless hasStatement(documentParser.Id)
    end

    def updateImportedStatements
        @sheetsAPI.saveColumn("D", @importedStatements)
    end
end