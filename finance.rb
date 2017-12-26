require 'bundler/setup'

require_relative 'sheets-api'
require_relative 'appsettings'
require_relative 'categorizer'
require_relative 'bmomcimportpdf'
require_relative 'applogger'

spreadsheetId = "1LkmAnd7vkW1AhwbgEOd1W-xmPiYJluaLzI1MDURFeFc";

def importFiles(files, categorizer, api)
    files.each do |file|
        parser = BMOMasterCardPDFParser.new(settings)
        transactions = parser.read(file)

        if settings.hasStatement(parser) then
            $logger.info "#{documentParser.Id} already imported"
            next
        end

        categorizer.updateTransactionsType(transactions)
        settings.addStatement(parser)

        rows = transactions.map { |transaction| transaction.toSheetRow }

        $logger.info "uploading #{rows.length} rows for #{documentParser.Id} ..."
        api.addRows( "Transactions", rows )
    end
end

api = SheetsAPI.new(spreadsheetId)
settings = AppSettings.new(api)
categorizer = Categorizer.new()

categorizer.validate(settings)
count = 0
total = 0
unknownDesc = []

ARGV.each do |file|
    parser = BMOMasterCardPDFParser.new(settings)
    transactions = parser.read(file)

    transactions.each do |transaction|
        if categorizer.guessTransactionType(transaction).nil?
            unknownDesc.push(transaction.description + " | " + transaction.amount.to_s+" | " + transaction.date.to_s) 
            total += transaction.amount
        end 
    end
    count += transactions.length
end
unknownDesc.sort!
puts "categorized #{categorizer.count} / #{count}"
puts "total: #{total}"
puts unknownDesc
