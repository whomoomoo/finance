require 'bundler/setup'

require_relative 'sheets-api'
require_relative 'appsettings'
require_relative 'categorizer'
require_relative 'import/bmomc'
require_relative 'import/simpliicsv'
require_relative 'import/tdvisa'
require_relative 'applogger'

def selectParser(fileName)
    return $parsers.find do |parser|
        parser.validFile(fileName)
    end
end

def importFiles(files)
    files.each do |file|
        parser = selectParser(file)

        if parser.nil? then
            $logger.warn "no parser found for #{file}"
            next
        end

        statement = parser.readFile(file)

        if $settings.hasStatement(statement) then
            $logger.info "#{statement.id} already imported"
            next
        end

        next

        $categorizer.updateTransactionsType(statement.transactions)
        $settings.addStatement(statement)

        rows = statement.transactions.map { |transaction| transaction.toSheetRow }

        $logger.info "uploading #{rows.length} rows for #{statement.id} ..."
        $api.addRows( "Transactions!A:A", rows )
    end
end

spreadsheetId = "1LkmAnd7vkW1AhwbgEOd1W-xmPiYJluaLzI1MDURFeFc";

$api = SheetsAPI.new(spreadsheetId)
$settings = AppSettings.new($api)
$categorizer = Categorizer.new()

$parsers = [BMOMasterCardPDFParser.new($settings), 
                SimpliiCheckingCSVParser.new($settings)]

$categorizer.validate($settings)

importFiles(ARGV)

# count = 0
# total = 0
# unknownDesc = []

# ARGV.each do |file|
#     parser = TDVisaPDFParser.new(settings)
#     transactions = parser.read(file)

#     transactions.each do |transaction|
#         if categorizer.guessTransactionType(transaction).nil?
#             unknownDesc.push(transaction.description + " | " + transaction.amount.to_s+" | " + transaction.date.to_s) 
#             total += transaction.amount
#         end 
#     end
#     count += transactions.length
# end
# unknownDesc.sort!
# puts "categorized #{categorizer.count} / #{count}"
# puts "total: #{total}"
# puts unknownDesc
