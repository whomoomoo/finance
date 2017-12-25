

class Transaction
    attr_accessor :account, :date, :amount, :type, :description

    def initialize(account, date, amount, description, type: nil)
        @account = account
        @date = date
        @amount = amount.to_f
        @type = type
        @description = description
    end
end