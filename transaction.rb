

class Transaction
    attr_accessor :account, :date, :amount, :type, :description, :refnum

    def initialize(account, date, amount, description, refnum, type: nil)
        @account = account
        @date = date
        @amount = amount.to_f
        @type = type
        @description = description
        @refnum = refnum
    end
end