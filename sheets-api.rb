require 'google/apis/sheets_v4'
require 'googleauth'
require 'googleauth/stores/file_token_store'

require 'fileutils'
require 'launchy'

spreadsheetId = "1LkmAnd7vkW1AhwbgEOd1W-xmPiYJluaLzI1MDURFeFc"
SheetsV4 = Google::Apis::SheetsV4

class SheetsAPI
    @spreadsheetId

    def initialize(spreadsheetId)
        @spreadsheetId = spreadsheetId

        # Initialize the API
        @service = SheetsV4::SheetsService.new
        @service.client_options.application_name = "Finance Importer"
        @service.authorization = authorize

        @updates = []
    end

    def loadRows(range)
        response = @service.get_spreadsheet_values(@spreadsheetId, range, 
            value_render_option: "UNFORMATTED_VALUE")
        return response.values
    end

    def loadColumns(range)
        response = @service.get_spreadsheet_values(@spreadsheetId, range, major_dimension:"COLUMNS", 
            value_render_option: "UNFORMATTED_VALUE")
        return response.values
    end

    def addRows(range, values)
        rangeObject = SheetsV4::ValueRange.new(major_dimension:"ROWS", range: range, values: values)
        @service.append_spreadsheet_value(@spreadsheetId, range, rangeObject,
             insert_data_option: "INSERT_ROWS", value_input_option: "RAW")
    end

    # preform all the pending batch updates
    def batchUpdate()
        @service.batch_update_values(@spreadsheetId, range, 
            SheetsV4::BatchUpdateValuesRequest.new(data: @updates, include_values_in_response: false))
        @updates = []
    end

    def clearValues(range)
        @service.clear_values(@spreadsheetId, range, SheetsV4::ClearValuesRequest.new())
    end
    private 

    OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
    CLIENT_SECRETS_PATH = 'client_secret.json'
    CREDENTIALS_PATH = File.join(Dir.home, '.credentials',
                             "sheets.googleapis.com-nodejs-finance-importer.yaml")
    SCOPE = SheetsV4::AUTH_SPREADSHEETS

    ##
    # Ensure valid credentials, either by restoring from the saved credentials
    # files or intitiating an OAuth2 authorization. If authorization is required,
    # the user's default browser will be launched to approve the request.
    #
    # @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
    def authorize
        FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

        client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
        token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)

        authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
        user_id = 'default'
        credentials = authorizer.get_credentials(user_id)
        if credentials.nil?
            $stdout.sync = true
            url = authorizer.get_authorization_url(base_url: OOB_URI)
            puts "Open the following URL in the browser and enter the " +
                "resulting code after authorization\n"
            puts url
            Launchy.open(url)
            print "code: "
            code = gets
            credentials = authorizer.
                get_and_store_credentials_from_code(user_id: user_id, code: code, base_url: OOB_URI)
        end
        credentials
    end
end
