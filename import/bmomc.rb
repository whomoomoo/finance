require 'pdf/reader'
require 'date'
require 'fileutils'

require_relative '../transaction'
require_relative '../applogger'
require_relative '../appsettings'

class BMOMasterCardPDFParser
    # attr_reader :baseDate, :balance, :prevBalance, :prevDate

    def initialize(appsettings)
        @appsettings = appsettings

        raise "unknown accout for parser #{accountId}" if @appsettings.accountNumByID[accountId].nil?
    end

    def read(fileName)
        $logger.debug "BMOMasterCardPDFParser parsing #{fileName}"
        @name = File.basename(fileName)
        reader = PDF::Reader.new(fileName)
        transactions = []
        
        reader.pages.each do |page|
            transactions.concat( readPage(page.text) )
        end

        raise "missing balance" if @balance.nil?  
        raise "missing base date" if @baseDate.nil?  
        raise "missing prev balance" if @prevBalance.nil?  
        raise "missing prev date" if @prevDate.nil?  

        sum = 0
        transactions.each do |transaction|
            sum += transaction.amount
        end

        sum += (@balance * -1) + @prevBalance

        raise "error parsing #{@name} summing transation check failed: #{sum}" unless sum.abs < 0.001  
                
        $logger.info "parsed #{@name}: #{transactions.length} transactions, DATA OK!"        

        return transactions
    end

    def accountId
        return "BMO-MC"
    end

    def Id
        return accountId + @baseDate.to_s
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

    def monthDayToDate(text)
        # check for transactions on this bill that happened in the previous month wich might 
        # have been in the previous year
        date = nil
        begin
            date = Date.parse(text)
        rescue ArgumentError 
            return nil
        end

        year = @baseDate.year
        if date.month != @baseDate.month && @baseDate.month <= 2 && date.month >= 11
            year -= 1
        elsif date.month != @baseDate.month && (date.month + 1) != @baseDate.month
            raise "#{@name} unknown transaction date year: #{date} statement date: #{@baseDate}"
        end
        return  Date.new(year, date.month, date.day)
    end

    def readPage(pageText)
        inTransactionTable = false
        transactions = []

        pageText.lines.each do |line|
            if @baseDate.nil? && /Statement Date\s+(.*)/.match(line) then
                @baseDate = Date.parse(Regexp.last_match(1))
                $logger.debug "Using #{@baseDate} as base date"
            end

            if @balance.nil? && /New Balance.*[$](-?\d+,?\d+\.\d+)/.match(line) then
                @balance = toNumber(Regexp.last_match(1))
                $logger.debug "Using #{@balance} as Balance"
            end

            if @prevBalance.nil? && /Previous Balance, (.*)  .*[$](-?\d+,?\d+\.\d+)/.match(line) then
                @prevBalance = toNumber(Regexp.last_match(2))
                $logger.debug "Using #{@prevBalance} as Previous Balance"
                @prevDate = Date.parse(Regexp.last_match(1))
                $logger.debug "Using #{@prevDate} as Previous Date"
            end

            if @prevBalance.nil? && /Previous Balance, (.*)  .*[$](-?\d+,?\d+\.\d+)/.match(line) then
                @prevBalance = toNumber(Regexp.last_match(2))
                $logger.debug "Using #{@prevBalance} as Previous Balance"
                @prevDate = Date.parse(Regexp.last_match(1))
                $logger.debug "Using #{@prevDate} as Previous Date"
            end

            if @cardNumberValidated.nil? && /Card Number\s+(\d+ \d+ \d+ \d+)/.match(line) then
                number = Regexp.last_match(1).gsub(/\s+/, '')
                expectedNumber = @appsettings.accountNumByID[accountId]

                raise "invalid account number, expect #{expectedNumber}, got #{number}" if number != expectedNumber

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

                    date = monthDayToDate(data[0])

                    next if date.nil?

                    raise "amount should never be zero!\n#{data}" if amount.abs < 0.001

                    transactions.push(Transaction.new(self.accountId, date, amount, data[2]))
                end
            end
        end

        return transactions
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
end
