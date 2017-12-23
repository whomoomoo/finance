require 'csv'

data = CSV.read(ARGV[0])

categoried = 0

map = { "Groceries" => ["SOBEYS", "EATING WELL ORGANICALL", "HERRLE'S COUNTRY FARM", "GLOGOWSKI EURO FOOD", "VINCENZO'S"],
        "Gas" =>  ["ESSO"],
        "Exersize" => ["GRAND RIVER ROCKS INC", "THE CORE CLIMBING GYM"],
        "Transfer" => ["PAYMENT RECEIVED - THANK YOU"],
        "Transport" => ["GRAND RIVER TRANSIT", "CITY CABS", ""],
        "Resterant" => ["DAIRY QUEEN", "BIANCA'S PIZZA", "271 WEST KITCHENER", "BALZAC'S COFFEE LTD", "PURE JUICE BAR", "HARVEYS", "SABABA FINE FOODS", "KINKAKU IZAKAYA", "FAT BASTARD BURRITO", "SWEET DREAMS TEASHOP","YE'S BUFFET", "SWISS CHALET", "ABE ERB", "KENZO RAMEN", "SUBWAY", "PHO DAU BO"],
        "House-Bills" => ["UNION GAS", "WATERLOO NORTH HYDRO", "KITCHENER WATER AND GAS", "KITCHENER-WILMOT HYDRO", "SENTEXCOMMUNICA"],
        "Mortgage" => ["MORTGAGE BNS MTGE DEPARTMENT"],
        "Bank-Fees" => ["ABM INTERAC CHARGE", "E-TRANSFER SEND S/C"],
        "Phone" => ["INTERNET BILL PAYMENT KOODO MOBILE"],
        "Health" => ["TALL PINES DENTAL","EFT CREDIT EQUITABLE LIFE OF CANADA", "POS MERCHANDISE GOOD PRACTICE"],
        "Bike" => ["ZIGGY S CYCLE", "KING STREET CYCLES"]
}

def hasStringsForTransactionClass(stringToMatch, subStrings)
    return false if stringToMatch.nil?

    subStrings.each do |string|
        if stringToMatch.upcase.include?(string) then
            return true
        end
    end
    return false
end

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