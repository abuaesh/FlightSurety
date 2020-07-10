"use strict";

import FlightSuretyApp from "../../build/contracts/FlightSuretyApp.json";
import Config from "./config.json";
import Web3 from "web3";
import express from "express";

// Define workspace variables
let network = "localhost";
let config = Config[network];
let web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace("http", "ws")));
let flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);

const ORACLES_COUNT = 20;
let FIRST_ORACLE_ADDRESS;
let LAST_ORACLE_ADDRESS;

// This is an IIFE (Immediately invoked function expression) just to provide this `async` keyword
(async function () {

    // Fetch web3 accounts
    let accounts = await web3.eth.getAccounts();

    FIRST_ORACLE_ADDRESS = accounts.length - ORACLES_COUNT -1;
    LAST_ORACLE_ADDRESS = ORACLES_COUNT + FIRST_ORACLE_ADDRESS;

    console.log(`Ganache returned ${accounts.length} accounts.`);
    console.log(`Server will use only ${ORACLES_COUNT} of these accounts for oracles.`);
    console.log(`Starting from accounts[${FIRST_ORACLE_ADDRESS}] for the first oracle.`);
    console.log(`Ending at accounts[${LAST_ORACLE_ADDRESS}] for the last oracle.`);

    // Use `.call` to fetch the current registration fee value
    let fee = await flightSuretyApp.methods.REGISTRATION_FEE().call({
        "from": accounts[0],
        "gas": 4712388,
        "gasPrice": 100000000000
    });

    console.log(`Smart Contract requires ${fee} wei to fund oracle registration.`);

    // Register all available oracles using the `accounts` array and await the process to finish
    await Promise.all(
        accounts.map(account => {
            return flightSuretyApp.methods.registerOracle().send({
                "from": account,
                "value": fee,
                "gas": 4712388,
                "gasPrice": 100000000000
            });
        })
    );

    console.log("Oracles server all set-up...\nOracles registered and assigned addresses...");
    console.log("Listening to a request event...");

    // Once all oracles are registered we can start listening to oracle requests
    flightSuretyApp.events.OracleRequest({
        "fromBlock": "latest"
    }, (error, event) => {
        if (error) {
            console.log(error);
        } else {

            // @TODO You have to assign the random status code and submit the `submitOracleResponse` within this block.
            console.log(event);
        }
    });

}());

// Simple HTTP server using express.js, you don't have to worry about it
const app = express();
app.get("/api", (req, res) => {
    res.send({
      message: "An API for use with your Dapp!"
    })
})

export default app;