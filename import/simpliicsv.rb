require 'date'
require 'csv'
require 'fileutils'

require_relative 'parser'

class SimpliiCSVParser < Parser
    def validFile(fileName)
        return /SIMPLII-.*\.csv/.match(File.basename(fileName))
    end

    def readFile(fileName)
        $logger.debug "SimpliiCSVParser parsing #{fileName}"
        @name = File.basename(fileName)
        rows = CSV.read(fileName)
        statement = Statement.new(fileName, accountId)

        raise "unknown CSV file" if rows[0][0] != "SIMPLII"

        validateAccountNumber rows[0][1].to_s
           
        debits = 0
        cridits = 0

        rows[2..-1].each do |row|
            amount = 0
            amount += row[2].strip.to_f unless row[2].nil?
            amount -= row[3].strip.to_f unless row[3].nil?

            debits += row[2].strip.to_f unless row[2].nil?
            cridits += row[3].strip.to_f unless row[3].nil?

            statement.addTransaction(Date.strptime(row[0], "%m/%d/%Y"), amount, row[1])
        end

        $logger.info "parsed #{@name}: #{statement.transactions.length} transactions, debits: #{debits} cridits: #{cridits}, DATA OK!"        

        return statement
    end
end

class SimpliiCheckingCSVParser < SimpliiCSVParser
    def accountId
        return "Simplii-checking"
    end
end

