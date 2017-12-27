require_relative '../transaction'
require_relative '../applogger'
require_relative '../appsettings'

class Parser
    def initialize(appsettings)
        @appsettings = appsettings

        self.validateAccount
    end

    def validateAccountNumber(accountNumber)
        expectedNumber = @appsettings.accountNumByID[accountId]

        raise "invalid account number, expect #{expectedNumber}, got #{accountNumber}" if accountNumber != expectedNumber
    end

    def validateAccount
        expectedNumber = @appsettings.accountNumByID[accountId]

        raise "unknown accout for parser #{accountId}" if @appsettings.accountNumByID[accountId].nil?
    end

    def accountId
        raise "must override accountId in subclass"
    end

    def validFile(fileName)
        return false
    end

    class Statement
        attr_accessor :fileName, :accountId, :id, :date, :transactions

        def initialize(fileName, accountId)
            @accountId = accountId
            @fileName = fileName
            @transactions = []
        end

        def total
            return @transactions.reduce(0) { |sum, transaction| sum + transaction.amount }
        end

        def addTransaction(date, amount, description)
            @transactions.push(Transaction.new(@accountId, date, amount, description))
        end
    end
end