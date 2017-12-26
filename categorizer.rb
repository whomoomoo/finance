require 'csv'
require_relative 'appsettings'
require_relative 'transaction'
require_relative 'accounttypes'
require_relative 'applogger'

class Categorizer
    attr_reader :count
    @count = 0

    @@map = { 
        "Bike" => ["ZIGGY S CYCLE", "KING STREET CYCLES"],
        "Books, Games, etc" => ["J&J CARDS", "WORDS WORTH BOOKS", "CHAPTERS", "LONG & MCQUADE"], 
        "Cash" => ["ABM WITHDRAWAL", "ABM INTERAC WITHDRAWAL"],
        "Car" =>  ["ESSO", "PETROCAN", "PETROMART", "PARKING", "ULTRAMAR", "HEFFNER", "HUSKY", "PARKLINK",
                    "ONROUTE #01165 CAMBRIDGE", "PIONEER", "CDN TIRE GASBAR"],
        "Clothes" => ["Old Navy", "NATIONAL SPORTS", "V&S DEPT.STORE"],
        "Costco" => ["COSTCO"],
        "Exersize" => ["GRAND RIVER ROCKS INC", "THE CORE CLIMBING GYM", "CAMBRIDGE KIPS",
                        "KITCHENER WATERLOO GYM", "CITY OF WATERLOO REC", "JUNCTION CLIMBING",
                        "A. R. KAUFMAN FAMILY", "REVOLUTION GYMN", "HUB MARKHAM", "HUB CLIMBING"],
        "Entertainment" => ["CINEMAS", "BEER STORE", "LCBO", "ADVENTURE ROOMS CANADA", 
                        "K-W LITTLE THEATRE", "LASER QUEST", "SNYDERS FAMILY FARM"],
        "Electronics" => ["CANADA COMPUTERS"],
        "Fees" => ["ABM INTERAC CHARGE", "E-TRANSFER SEND S/C", "EFT CREDIT e-Transfer Fee Promo CR"],
        "House" => ["CDN TIRE STORE", "CHASLES PLUMBING", "THE HOME DEPOT", "RONA", "LOWES", 
                    "SCHWEITZER'S PLUMBING", "SCHWEITZERS PLUMBING", "SWANSON'S HOME HARDWAR", "SCANICA FURNITURE", 
                    "SWANSON'S HOME HARDWAR", "SHERIDAN NURSERIES", "ROYAL CITY NURSERY",
                    "HEER'S PAINT", "GLENBRIAR HM HWR", "BED BATH & BEYOND", "CONESTOGO MECHANICAL",
                "BLINDS TO GO", "HUDSON's BAY HOME", "APPLIANCE SCRATCH", "TA APPLIANCE"],
        "House-Bills" => ["UNION GAS", "WATERLOO NORTH HYDRO", "KITCHENER WATER AND GAS", 
                        "KITCHENER-WILMOT HYDRO", "SENTEXCOMMUNICA", "PROPERTY TAXES City of Kitchener"],
        "Health" => ["TALL PINES DENTAL","EFT CREDIT EQUITABLE LIFE OF CANADA", 
                        "POS MERCHANDISE GOOD PRACTICE", "THE BOARDWALK PHARMACY", "EYES ON KING",
                        "MEDICAL PHARMACIES", "SQ *LEE HORTON"],
        "Groceries" => ["SOBEYS", "EATING WELL ORGANICALL", "HERRLE'S COUNTRY FARM", "GLOGOWSKI EURO FOOD", 
                        "VINCENZO'S", "WATERLOO SQUARE VALUMA", "ZEHRS", "ONKAR FOODS", "FULL CIRCLE",
                        "BRADYS MEATS", "WATERLOO CENTRAL SUPER", "SHOPPERS DRUG MART", "SHOPPERSDRUGMART",
                        "PHARMA PLUS DRUGMARTS", "LONGO'S", "AMBROSIA THORNHILL", "SHAKESPEARE PIES"],
        "Mortgage" => ["MORTGAGE BNS MTGE DEPARTMENT"],
        "Moving" => ["U-HAUL", "UHAUL"],
        "Misc" => ["B.J.HAIRSTYLING"],
        "Phone" => ["KOODO"],
        "Resterant" => ["DAIRY QUEEN", "271 WEST KITCHENER", "BALZAC'S COFFEE LTD", 
                        "PURE JUICE BAR", "HARVEYS", "SABABA FINE FOODS", "KINKAKU IZAKAYA", 
                        "FAT BASTARD BURRITO", "SWEET DREAMS TEASHOP","YE'S BUFFET", "SWISS CHALET", 
                        "ABE ERB", "KENZO RAMEN", "SUBWAY", "PHO DAU BO", "TACO FARM", "JACK ASTOR'S",
                        "ARABESQUE", "UNITY BAKING", "TIM HORTONS", "QUICK SANDWICHES", "BURRITO BOYZ",
                        "PIZZA", "THE WORKS", "SUSHI", "COUNTRY STYLE", "GRAIN OF SALT",
                        "AMERICA LATINA VARIETY", "BREAD BAR", "CAFE PYRUS", "VEGETARIAN FASTFOOD",
                        "MEL'S DINER", "MCCABE'S", "MCMULLAN'S", "RESTAURANT", "JANE BOND", "CHIPOTLE",
                        "SEVEN SHORES URBAN MAR", "SETTLEMENT CO", "SHAWARMA", "HUETHER HOTEL",
                        "THE PUB ON KING", "THIRSTY'S BAR", "FRESHWEST GRILL", "B.GOOD TORONTO",
                        "WENDY'S", "HOLY GUACAMOLE"],
        "RRSP" => ["INVESTMENT CANADIAN SHAREOWNERS", "INTERNET BILL PAYMENT NEXTSTEP GREAT-WEST LIFE"
        ],
        "Transfer" => ["PAYMENT RECEIVED - THANK YOU", "INTERNET BILL PAYMENT MASTERCARD", 
                        "INTERNET BILL PAYMENT VISA", "TRANSFER IN", "TRANSFER OUT" ],
        "Transport" => ["GRAND RIVER TRANSIT", "CITY CABS", "WATERLOO TAXI"],
        "Vacation" => ["SILENT LAKE", "VIA RAIL"],
        "Work" => ["PAYROLL DEPOSIT", "EFT CREDIT CANADA"],
    }

    @@mapWithType = {
        AccountTypes::EXPENSE => {
            "Fees"=> ["INTEREST", "BMO FUNDS TRANSFER"]
        },
        AccountTypes::REVENUE => {
            "Investment"=> ["INTEREST"]
        }
    }

    def validate(appsettings)
        $logger.info "validating categorizer map..."
        @appsettings = appsettings

        @@map.keys.each do |transactionType|
            unless appsettings.transactionTypes.find_index(transactionType) then
                raise "unknown transactionType #{transactionType}"
            end
        end

        # check no string is a sub string of another
        @@map.keys.each do |transactionType|
            @@map[transactionType].each do |string|
                @@map.keys.each do |transactionType2|
                    next if transactionType == transactionType2

                    @@map[transactionType2].each do |string2|
                        raise "two different transactionType have overlapping huristic :\n"+
                        "#{transactionType}, #{string}\n" +
                        "#{transactionType2}, #{string2}\n" if string.include?(string2)
                    end
                end
            end
        end
    end

    def updateTransactionType(transation)
        return unless transation.type.nil? || transation.type == "Misc"

        type = guessTransactionType(transation)
        unless type.nil? then
            transation.type = type
        else
            if transation.amount > 0
                transaction.type = "Misc"
            else
                transaction.type = "Misc-In"
            end
        end
    end

    def updateTransactionsType(transations)
        @count = 0
        transations.each do |transaction|
            updateTransactionType(transaction)
        end
        $logger.info "categorized #{@categoried} out of #{transations.length}"
    end

    def guessTransactionType(transaction)
        return nil if transaction.description.nil?
        @count = 0 if @count.nil?

        type = matchingType(@@map, transaction.description)
        unless type.nil? then
            @count += 1
            return type
        end

        accountType = @appsettings.accountTypeByName[transaction.account]

        type = matchingType(@@mapWithType[accountType], transaction.description)
        unless type.nil? then
            @count += 1
            return type
        end

        if transaction.description.include? "INSURANCE MELOCHE MONNEX/SECURITE NAT'L CHEQUE"
            if transaction.amount > 90
                return "Car"
            else
                return "House-Bills"
            end
        end

        return nil
    end

    def matchingType(map, text)
        map.keys.each do |transactionType|
            map[transactionType].each do |string|
                if text.upcase.include?(string.upcase) then
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