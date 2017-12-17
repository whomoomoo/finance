
let GoogleSheetsAPI = require("./google-api-service")
let assert = require("assert")

let spreadsheetId = "1LkmAnd7vkW1AhwbgEOd1W-xmPiYJluaLzI1MDURFeFc";
let sheetsAPI = new GoogleSheetsAPI.API(spreadsheetId);

let transactionTypes = [];
let accountNames = {};
let refnums = [];

let commandMap = {
    import (args) {
        let file = args[0];
    }
};

function start(afterStart) {
    let connects = 0;

    function doAfterStart() {
        connects++;

        if (connects === 2) {
            console.log("successful connection to google sheets");
            
            afterStart()
        }
    }

    sheetsAPI.connect("./client_secret.json", (api) => {
        api.loadColumns('Settings!A2:C', (settingsData) => {
            transactionTypes = settingsData[0]

            assert.strictEqual(settingsData[1].length, settingsData[2].length)
            settingsData[1].forEach((key, i) => accountNames[key.replace(/ /g, '')] = settingsData[2][i]);

            doAfterStart();
        });

        api.load('Transactions!F2:F', (settingsData) => {
            if (settingsData) {
                refnums = settingsData[0]
            }
            
            doAfterStart();            
        });
    });
}

start(() => {
    let action = process.argv[2]

    if (commandMap[action]) {
        let args = process.argv.slice(3)

        commandMap[action](args)
    } else {
        console.log("action %s unknown. List of known actions:", action, 
            Object.getOwnPropertyNames(commandMap));
    }
});