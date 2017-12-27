require 'pdf/reader'
require 'date'
require 'fileutils'

require_relative 'parser'

class BMOMasterCardPDFParser < Parser
    # attr_reader :baseDate, :balance, :prevBalance, :prevDate

    def validFile(fileName)
        return /eStatement_\d+-\d+-\d+\.pdf/.match(File.basename(fileName))
    end

    def readFile(fileName)
        $logger.debug "BMOMasterCardPDFParser parsing #{fileName}"
        @name = File.basename(fileName)
        statement = CrediCardStatement.new(fileName, accountId)
        reader = PDF::Reader.new(fileName)

        @cardNumberValidated = false
        
        reader.pages.each do |page|
            readPage(page.text, statement)
        end

        raise "missing balance" if statement.balance.nil?  
        raise "missing base date" if statement.date.nil?  
        raise "missing prev balance" if statement.prevBalance.nil?  
        raise "missing prev date" if statement.prevDate.nil?  

        sum = statement.total - statement.balance + statement.prevBalance

        $logger.warn "error parsing #{@name} summing transation check failed: #{sum}" unless sum.abs < 0.001  
                
        $logger.info "parsed #{@name}: #{statement.transactions.length} transactions, DATA OK!"        

        return statement
    end

    def accountId
        return "BMO-MC"
    end

    private

    def toNumber(text)
        multiplier = 1
        if /CR/.match(text) then
            multiplier = -1
            text.sub!("CR", "")
        end
        return text.strip.sub(",", "").to_f * multiplier
    end

    def monthDayToDate(text, statement)
        # check for transactions on this bill that happened in the previous month wich might 
        # have been in the previous year
        date = nil
        begin
            date = Date.parse(text)
        rescue ArgumentError 
            return nil
        end

        year = statement.date.year
        if date.month != statement.date.month && statement.date.month <= 2 && date.month >= 11
            year -= 1
        elsif date.month != statement.date.month && (date.month + 1) != statement.date.month
            raise "#{@name} unknown transaction date year: #{date} statement date: #{statement.date}"
        end
        return  Date.new(year, date.month, date.day)
    end

    def readPage(pageText, statement)
        inTransactionTable = false

        pageText.lines.each do |line|
            if statement.date.nil? && /Statement Date\s+(.*)/.match(line) then
                statement.date = Date.parse(Regexp.last_match(1))
                $logger.debug "Using #{statement.date} as base date"
            end

            if statement.balance.nil? && /New Balance.*[$](-?\d+,?\d+\.\d+)/.match(line) then
                statement.balance = toNumber(Regexp.last_match(1))
                $logger.debug "Using #{statement.balance} as Balance"
            end

            if statement.prevBalance.nil? && /Previous Balance, (.*)  .*[$](-?\d+,?\d+\.\d+)/.match(line) then
                statement.prevBalance = toNumber(Regexp.last_match(2))
                $logger.debug "Using #{statement.prevBalance} as Previous Balance"
                statement.prevDate = Date.parse(Regexp.last_match(1))
                $logger.debug "Using #{statement.prevDate} as Previous Date"
            end

            if @cardNumberValidated.nil? && /Card Number\s+(\d+ \d+ \d+ \d+)/.match(line) then
                number = Regexp.last_match(1).gsub(/\s+/, '')
                validateAccountNumber number

                @cardNumberValidated = true
            end

            if !inTransactionTable && /\w+\s+\w+\s+DESCRIPTION\s+REFERENCE NO/.match(line) then
                inTransactionTable = true
            end

            if inTransactionTable then
                if /^\s*(\w+\.?\s\d+)\s+(\w+\.?\s\d+)/.match(line) then
                    data = splitColumns(line, [10, 10, 64, 16])

                    data.each do |dataElement|
                        dataElement.strip!
                    end

                    amount = toNumber(data[4])
                    
                    # compress multiple whitespaces into one
                    data[2].gsub!(/\s+/, " ")

                    date = monthDayToDate(data[0], statement)

                    next if date.nil?

                    raise "amount should never be zero!\n#{data}" if amount.abs < 0.001

                    statement.addTransaction(date, amount, data[2])
                end
            end
        end
    end

    def splitColumns(line, columns)
        sum = columns.reduce(0, :+)

        return nil if sum >= line.length

        data = []
        last = 0
        columns.each do |column|
            data.push(line[last, column])
            last += column
        end
        data.push(line[last..-1])
        return data
    end

    class CrediCardStatement < Statement
        attr_accessor :balance, :prevBalance, :prevDate

        def id
            return accountId + "." + @date.to_s
        end
    end
end
