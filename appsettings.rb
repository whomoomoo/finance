require_relative 'sheets-api'
require_relative 'applogger'
require_relative 'accounttypes'

class AppSettings
    attr_reader :transactionTypes, :accountsByID, :importedStatements, :accountTypeByName

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
        settingsData[1].each_index do |index|
            key = settingsData[1][index]
            type = AccountTypes.const_get(settingsData[3][index].upcase)

            raise "unknown account type #{settingsData[3][index].upcase}" if type.nil?

            @accountsByID[key.gsub(/\s+/, '')] = settingsData[2][index]
            @accountTypeByName[settingsData[2][index].strip] = type
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