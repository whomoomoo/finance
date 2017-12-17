let fileSystem = require('fs');
let readline = require('readline');
let google = require('googleapis');
let googleAuth = require('google-auth-library');
let openurl = require('openurl');

// If modifying these scopes, delete your previously saved credentials
// at ~/.credentials/sheets.googleapis.com-nodejs-quickstart.json
let SCOPES = ['https://www.googleapis.com/auth/spreadsheets'];
let TOKEN_DIR = (process.env.HOME || process.env.HOMEPATH ||
    process.env.USERPROFILE) + '/.credentials/';
let TOKEN_PATH = TOKEN_DIR + 'sheets.googleapis.com-nodejs-finance-importer.json';

class GoogleSheetsAPI {
    constructor (spreadsheetId) {
        this.spreadsheetId = spreadsheetId
    }

    connect(oathKeyFilePath, onConnect) {
        // Load client secrets from a local file.
        let contents = fileSystem.readFileSync(oathKeyFilePath);

        // Authorize a client with the loaded credentials, then call the
        // Google Sheets API.
        var credentials = JSON.parse(contents);
        var auth = new googleAuth();
        this.oauth2Client = new auth.OAuth2(credentials.installed.client_id, 
            credentials.installed.client_secret, 
            credentials.installed.redirect_uris[0]);
    
        // Check if we have previously stored a token.
        if (!fileSystem.existsSync(TOKEN_PATH)) {
            this.createToken(onConnect);
        } else {
            let token = fileSystem.readFileSync(TOKEN_PATH);
            this.oauth2Client.credentials = JSON.parse(token);
            onConnect(this);
        }
    }

    load(range, onLoad) {
        var sheets = google.sheets('v4');
        sheets.spreadsheets.values.get({
          auth: this.oauth2Client,
          spreadsheetId: this.spreadsheetId,
          range: range,
        }, (error, response) => {
          if (error) {
            console.error('The API returned an error: ', error);
          } else {
            onLoad(response.values)
          }
        });
    }

    loadColumns(range, onLoad) {
        var sheets = google.sheets('v4');
        sheets.spreadsheets.values.get({
          auth: this.oauth2Client,
          spreadsheetId: this.spreadsheetId,
          range: range,
          majorDimension: 'COLUMNS',
        }, (error, response) => {
          if (error) {
            console.error('The API returned an error: ', error);
          } else {
            onLoad(response.values)
          }
        });
    }

    /**
     * Get and store new token after prompting for user authorization, and then
     * execute the given callback with the authorized OAuth2 client.
     *
     * @param {getEventsCallback} onConnect The callback to call with the authorized
     *     client.
     */
    createToken(onConnect) {
        var authUrl = this.oauth2Client.generateAuthUrl({
            access_type: 'offline',
            scope: SCOPES
        });
        console.log('Authorize via the browser opened by the app \n',
            '(visit this url: %s if it fails to open)', authUrl);

        openurl.open(authUrl)
        var readlineInterface = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });
        readlineInterface.question('Enter the code from that page here: ', (code) => {
                readlineInterface.close();
                oauth2Client.getToken(code, (err, token) => {
                if (err) {
                    console.error('Error while trying to retrieve access token', err);
                    return;
                }
                oauth2Client.credentials = token;
                this.storeToken(token);
                onConnect(this);
            });
        });
    }

    /**
     * Store token to disk be used in later program executions.
     *
     * @param {Object} token The token to store to disk.
     */
    storeToken(token) {
        try {
            fileSystem.mkdirSync(TOKEN_DIR);
        } catch (err) {
            if (err.code != 'EEXIST') {
                throw err;
            }
        }
        fileSystem.writeFile(TOKEN_PATH, JSON.stringify(token));
        console.log('Token stored to ' + TOKEN_PATH);
    }
}


module.exports = {
    API : GoogleSheetsAPI
}