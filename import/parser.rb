require_relative '../transaction'
require_relative '../applogger'
require_relative '../appsettings'

class Parser
    def initialize(appsettings)
        @appsettings = appsettings

        raise "unknown accout for parser #{accountId}" if @appsettings.accountNumByID[accountId].nil?
    end

    def validateAccountNumber(accountNumber)
        expectedNumber = @appsettings.accountNumByID[accountId]

        raise "invalid account number, expect #{expectedNumber}, got #{accountNumber}" if accountNumber != expectedNumber
    end

    def accountId
        raise "must override accountId in subclass"
    end
end