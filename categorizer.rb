require 'csv'
require_relative 'appsettings'
require_relative 'transaction'
require_relative 'accounttypes'
require_relative 'applogger'

class Categorizer
    attr_reader :count
    @count = 0

    @@map = { 
        "Groceries" => ["SOBEYS", "EATING WELL ORGANICALL", "HERRLE'S COUNTRY FARM", "GLOGOWSKI EURO FOOD", 
                        "VINCENZO'S", "WATERLOO SQUARE VALUMA", "ZEHRS", "ONKAR FOODS", "FULL CIRCLE",
                        "BRADYS MEATS", "WATERLOO CENTRAL SUPER", "SHOPPERS DRUG MART", "SHOPPERSDRUGMART",
                        "PHARMA PLUS DRUGMARTS", "LONGO'S", "AMBROSIA THORNHILL", "SHAKESPEARE PIES"],
        "Car" =>  ["ESSO", "PETROCAN", "PETROMART", "PARKING", "ULTRAMAR", "HEFFNER", "HUSKY", "PARKLINK",
                    "ONROUTE #01165 CAMBRIDGE"],
        "Exersize" => ["GRAND RIVER ROCKS INC", "THE CORE CLIMBING GYM", "CAMBRIDGE KIPS",
                        "KITCHENER WATERLOO GYM", "CITY OF WATERLOO REC", "JUNCTION CLIMBING",
                        "A. R. KAUFMAN FAMILY"],
        "Transfer" => ["PAYMENT RECEIVED - THANK YOU"],
        "Transport" => ["GRAND RIVER TRANSIT", "CITY CABS", "WATERLOO TAXI"],
        "Resterant" => ["DAIRY QUEEN", "271 WEST KITCHENER", "BALZAC'S COFFEE LTD", 
                        "PURE JUICE BAR", "HARVEYS", "SABABA FINE FOODS", "KINKAKU IZAKAYA", 
                        "FAT BASTARD BURRITO", "SWEET DREAMS TEASHOP","YE'S BUFFET", "SWISS CHALET", 
                        "ABE ERB", "KENZO RAMEN", "SUBWAY", "PHO DAU BO", "TACO FARM", "JACK ASTOR'S",
                        "ARABESQUE", "UNITY BAKING", "TIM HORTONS", "QUICK SANDWICHES", "BURRITO BOYZ",
                        "PIZZA", "THE WORKS", "SUSHI", "COUNTRY STYLE", "GRAIN OF SALT",
                        "AMERICA LATINA VARIETY", "BREAD BAR", "CAFE PYRUS", "VEGETARIAN FASTFOOD",
                        "MEL'S DINER", "MCCABE'S", "MCMULLAN'S", "RESTAURANT", "JANE BOND", "CHIPOTLE",
                        "SEVEN SHORES URBAN MAR", "SETTLEMENT CO", "SHAWARMA", "HUETHER HOTEL",
                        "THE PUB ON KING", "THIRSTY'S BAR"],
        "House-Bills" => ["UNION GAS", "WATERLOO NORTH HYDRO", "KITCHENER WATER AND GAS", 
                          "KITCHENER-WILMOT HYDRO", "SENTEXCOMMUNICA"],
        "Mortgage" => ["MORTGAGE BNS MTGE DEPARTMENT"],
        "Bank-Fees" => ["ABM INTERAC CHARGE", "E-TRANSFER SEND S/C"],
        "Phone" => ["KOODO"],
        "Health" => ["TALL PINES DENTAL","EFT CREDIT EQUITABLE LIFE OF CANADA", 
                     "POS MERCHANDISE GOOD PRACTICE", "THE BOARDWALK PHARMACY", "EYES ON KING",
                     "MEDICAL PHARMACIES"],
        "Bike" => ["ZIGGY S CYCLE", "KING STREET CYCLES"],
        "House" => ["CDN TIRE STORE", "CHASLES PLUMBING", "THE HOME DEPOT", "RONA", "LOWES", 
                    "SCHWEITZER'S PLUMBING", "SWANSON'S HOME HARDWAR", "SCANICA FURNITURE", 
                    "SWANSON'S HOME HARDWAR", "SHERIDAN NURSERIES", "ROYAL CITY NURSERY",
                    "HEER'S PAINT", "GLENBRIAR HM HWR", "BED BATH & BEYOND", "CONESTOGO MECHANICAL",
                "BLINDS TO GO", "HUDSON's BAY HOME", "APPLIANCE SCRATCH", "TA APPLIANCE"],
        "Misc" => ["B.J.HAIRSTYLING"],
        "Books" => ["WORDS WORTH BOOKS", "CHAPTERS"],
        "Entertainment" => ["CINEMAS", "BEER STORE", "LCBO", "ADVENTURE ROOMS CANADA", 
                            "K-W LITTLE THEATRE", "LASER QUEST", "SNYDERS FAMILY FARM"],
        "Electronics" => ["CANADA COMPUTERS"],
        "Games" => ["J&J CARDS"], 
        "Clothes" => ["Old Navy", "NATIONAL SPORTS", "V&S DEPT.STORE"],
        "Vacation" => ["SILENT LAKE", "VIA RAIL"],
        "Moving" => ["U-HAUL", "UHAUL"]
    }

    @@mapWithType = {
        AccountTypes::EXPENSE => {
            "Fees"=> ["INTEREST", "BMO FUNDS TRANSFER"]
        },
        AccountTypes::REVENUE => {
            "Fees"=> ["Investment"]
        }
    }

    def validate(appsettings)
        $logger.info "validating categorizer map..."
        @@map.keys.each do |transactionType|
            unless appsettings.transactionTypes.find_index(transactionType) then
                raise "unknown transactionType #{transactionType}"
            end
        end
    end

    def guessTransactionType(transation)
        return unless transation.type.nil? || transation.type == "Misc"

        if guessTransactionTypeFromDescription(transation.description) then
            transation.type = transactionType
            return
        end
    end

    def setTransactionsTypeFromDescription(transations)
        @count = 0
        transations.each do |transaction|
            guessTransactionTypeFromDescription(transaction)
        end
        $logger.info "categorized #{@categoried} out of #{transations.length}"
    end

    def guessTransactionTypeFromDescription(description, accountType)
        return nil if description.nil?
        @count = 0 if @count.nil?

        @@map.keys.each do |transactionType|
            @@map[transactionType].each do |string|
                if description.upcase.include?(string.upcase) then
                    @count += 1
                    return transactionType
                end
            end
        end

        @@mapWithType[accountType].keys.each do |transactionType|
            @@mapWithType[accountType][transactionType].each do |string|
                if description.upcase.include?(string.upcase) then
                    @count += 1
                    return transactionType
                end
            end
        end

        return nil
    end
end

=begin 
data.each do |row|
    map.keys.each do |transactionClass|
        if hasStringsForTransactionClass(row[3], map[transactionClass]) then
            row[2] = transactionClass
            categoried += 1
        end
    end
end

STDERR.puts "categorized #{categoried} out of #{data.length} rows"
puts data.map(&:to_csv).join 
=end