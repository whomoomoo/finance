require 'pdf/reader'
require 'date'
require 'csv'
require_relative 'transaction'

class BMOMasterCardPDFParser
    @baseDate = nil
    @balance = nil
    @prevBalance = nil

    def read(fileName)
        reader = PDF::Reader.new(fileName)
        transactions = []
        
        reader.pages.each do |page|
            transactions.concat( readPage(page.text) )
        end

        raise "missing balance" if @balance.nil?  
        raise "missing base date" if @baseDate.nil?  
        raise "missing prev balance" if @prevBalance.nil?  
        
        sum = 0
        transactions.each do |transaction|
            sum += transaction.amount
        end

        sum += (@balance * -1) + @prevBalance

        raise "error parsing summing transation check failed: #{sum}" unless sum < 0.001   
        
        STDERR.puts "#{transactions.length} transactions"        
        STDERR.puts "DATA OK!"

        return transactions
    end

    private

    def toNumber(text)
        return text.strip.sub(",", "").to_f
    end

    def readPage(pageText)
        inTransactionTable = false
        transactions = []

        pageText.lines.each do |line|
            if @baseDate.nil? && /Statement Date\s+(.*)/.match(line) then
                @baseDate = Date.parse(Regexp.last_match(1))
                STDERR.puts "Using #{@baseDate} as base date"
            end

            if @balance.nil? && /New Balance.*[$](-?\d+,?\d+\.\d+)/.match(line) then
                @balance = toNumber(Regexp.last_match(1))
                STDERR.puts "Using #{@balance} as Balance"
            end

            if @prevBalance.nil? && /Previous Balance.*[$](-?\d+,?\d+\.\d+)/.match(line) then
                @prevBalance = toNumber(Regexp.last_match(1))
                STDERR.puts "Using #{@prevBalance} as Previous Balance"
            end

            if !inTransactionTable && /\w+\s+\w+\s+DESCRIPTION\s+REFERENCE NO/.match(line) then
                inTransactionTable = true
            end

            if inTransactionTable then
                if /^\s*(\w+\.?\s\d+)\s+(\w+\.?\s\d+)/.match(line) then
                    data = line.unpack("A10A10A63A25A30")

                    data.each do |dataElement|
                        dataElement.strip!
                    end

                    amount = data[4]
                    if /CR/.match(amount) then
                        amount = toNumber(amount.sub("CR", "")) * -1
                    else
                        amount = amount.to_f
                    end

                    # compress multiple whitespaces into one
                    data[2].gsub!(/\s+/, " ")

                    begin
                        # check for transactions on this bill that happened in the previous month wich might 
                        # have been in the previous year
                        date = Date.parse(data[0])
                        year = @baseDate.year
                        if date.month == 11 || date.month == 12
                            year -= 1
                        end

                        date = Date.new(year, date.month, date.day)

                        transactions.push(Transaction.new("BMO-MC", date, amount, data[2], " "))
                            
                        # ["BMO-MC", data[3], data[0], " ", data[4], data[2]])
                    rescue ArgumentError
                        STDERR.puts "#{line.strip} not valid data"
                    end
                end
            end
        end

        return transactions
    end
end

ARGV.each do |file|
    STDERR.puts "converting #{file}"    
    parser = BMOMasterCardPDFParser.new()
    transactions = parser.read(file)

    print transactions.map(&:inspect).join("\n") #.map(&:to_csv).join
end
STDERR.puts "coverted #{ARGV.length} files"    
