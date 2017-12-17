
let GoogleSheetsAPI = require("./google-api-service")

let spreadsheetId = "1LkmAnd7vkW1AhwbgEOd1W-xmPiYJluaLzI1MDURFeFc";
let sheetsAPI = new GoogleSheetsAPI.API(spreadsheetId);

let transactionTypes = [];
let accountNames = {};
let refnums = [];

sheetsAPI.connect("./client_secret.json", function(api){
    api.loadColumns('Settings!A2:C', function(settingsData) {
        console.log(settingsData)

        transactionTypes = settingsData[0]

        // assert keys.lenght == values.lnegth?
        settingsData[1].forEach((key, i) => accountNames[key.replace(/ /g, '')] = settingsData[2][i]);

        console.log("transactionTypes: ", transactionTypes);
        console.log("accountNames: ", accountNames);        
    });

    api.load('Transactions!F2:F', function(settingsData) {
        if (settingsData) {
            refnums = settingsData[0]
        }
        console.log("refnums: ", refnums);        
    });
});
