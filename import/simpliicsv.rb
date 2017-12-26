require 'date'
require 'csv'
require 'fileutils'

require_relative '../transaction'
require_relative '../applogger'
require_relative '../appsettings'

class SimpliiCSVParser
    def initialize(appsettings)
        @appsettings = appsettings

        raise "unknown accout for parser #{accountId}" if @appsettings.accountNumByID[accountId].nil?
    end

    def read(fileName)
        $logger.debug "BMOMasterCardPDFParser parsing #{fileName}"
        @name = File.basename(fileName)
        rows = CSV.read(fileName)

        raise "unknown CSV file" if rows[0][0] != "SIMPLII"

        accountNumber = rows[0][1].to_s
        expectedNumber = @appsettings.accountNumByID[accountId]

        raise "invalid account number, expect #{expectedNumber}, got #{accountNumber}" if accountNumber != expectedNumber

        transactions = []
    
        debits = 0
        cridits = 0

        rows[2..-1].each do |row|
            puts row.inspect
            amount = 0
            amount += row[2].strip.to_f unless row[2].nil?
            amount -= row[3].strip.to_f unless row[3].nil?

            debits += row[2].strip.to_f unless row[2].nil?
            cridits += row[3].strip.to_f unless row[3].nil?

            transactions.push( Transaction.new(accountId, Date.strptime(row[0], "%m/%d/%Y"), amount, row[1]) )
        end

        puts transactions.inspect

        $logger.info "parsed #{@name}: #{transactions.length} transactions, debits: #{debits} cridits: #{cridits}, DATA OK!"        

        return transactions
    end
end

class SimpliiCheckingCSVParser < SimpliiCSVParser
    def accountId
        return "Simplii-checking"
    end
end

