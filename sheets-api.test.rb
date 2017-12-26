require "minitest/autorun"
require_relative 'sheets-api'

class TestGoogleSheets < Minitest::Test
    @@spreadsheetId = "1CHEE4THsr5i6HeP-wRo9xEebtlt2-zFx4Xk5R6uJOF4"
    @@api = SheetsAPI.new(@@spreadsheetId)

    def setup
        @@api.clearValues("Sheet1")
    end

    def test_addOneRow
        @@api.addRows("Sheet1", [["a", "b", "c"]])

        rows = @@api.loadRows("Sheet1!A:C")
        assert_equal [["a", "b", "c"]], rows
    end

    def test_addTwoRows
        @@api.addRows("Sheet1", [["a", "b", "c"]])
        @@api.addRows("Sheet1", [["1", "2", "3"]])

        rows = @@api.loadRows("Sheet1!A:C")
        assert_equal [["a", "b", "c"], ["1", "2", "3"]], rows
    end

    def test_saveNumber
        @@api.addRows("Sheet1", [[1, 2, 3]])

        rows = @@api.loadRows("Sheet1!A:C")
        assert_equal [[1, 2, 3]], rows
    end

    def test_saveDate
        now = Date.today
        @@api.addRows("Sheet1", [[now]])

        rows = @@api.loadRows("Sheet1!A:C")
        assert_equal now, Date.parse(rows[0][0])
    end

    def test_loadColumn
        @@api.addRows("Sheet1", [["a", "b", "c"]])
        @@api.addRows("Sheet1", [["1", "2", "3"]])
        @@api.addRows("Sheet1", [["x", "y", "z"]])

        columns = @@api.loadColumns("Sheet1!B:B")
        assert_equal [["b", "2", "y"]], columns
    end

    def test_loadColumn
        @@api.addRows("Sheet1", [["a", "b", "c"]])
        @@api.addRows("Sheet1", [["1", "2", "3"]])
        @@api.addRows("Sheet1", [["x", "y", "z"]])

        columns = @@api.loadColumns("Sheet1!B:C")
        assert_equal [["b", "2", "y"], ["c", "3", "z"]], columns
    end
end