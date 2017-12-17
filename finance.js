
let GoogleSheetsAPI = require("./google-api-service")

let spreadsheetId = "1LkmAnd7vkW1AhwbgEOd1W-xmPiYJluaLzI1MDURFeFc";
let sheetsAPI = new GoogleSheetsAPI.GoogleSheetsAPI(spreadsheetId);

let transactionTypes;
let accountNames;

sheetsAPI.connect("./client_secret.json", function(api){
    api.load('Settings!A2:C', function(rows) {
        for (let row of rows) {
            // Print columns A and E, which correspond to indices 0 and 4.
            console.log(row);
          }
    });
});
