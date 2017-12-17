
let GoogleSheetsAPI = require("./google-api-service")

let spreadsheetId = "1LkmAnd7vkW1AhwbgEOd1W-xmPiYJluaLzI1MDURFeFc";
let sheetsAPI = new GoogleSheetsAPI.API(spreadsheetId);

let transactionTypes;
let accountNames;

sheetsAPI.connect("./client_secret.json", function(api){
    api.load('Settings!A2:C', function(settingsData) {
        for (let row of settingsData) {
            console.log(row);
          }
    });
});
