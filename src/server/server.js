
import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';
import express from 'express';

// Define workspace variables
let network = 'localhost';
let config = Config[network];
let web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws')));
let flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);

let oracles = [];
var ORACLES_COUNT = 20, FIRST_ORACLE_ADDRESS, LAST_ORACLE_ADDRESS;

web3.eth.getAccounts().then(accounts => {
  // Register 20 oracles
  FIRST_ORACLE_ADDRESS = accounts.length - ORACLES_COUNT -1;
  LAST_ORACLE_ADDRESS = ORACLES_COUNT + FIRST_ORACLE_ADDRESS;
  console.log('Ganache returned '+accounts.length+' accounts.');
  console.log('Server will use only '+ORACLES_COUNT+' of these accounts for oracles.');
  console.log('Starting from accounts['+FIRST_ORACLE_ADDRESS+'] for the first oracle.');
  console.log('Ending at accounts['+LAST_ORACLE_ADDRESS+'] for the last oracle.');

  // Initialize oracles addresses and indexes with smart contract
  flightSuretyApp.methods.REGISTRATION_FEE().call({
    "from": accounts[0],
    "gas": 4712388,
    "gasPrice": 100000000000
  }).then(fee => { 
    console.log('Smart Contract requires ('+fee+') ethers to fund oracle registration.');
    accounts.forEach(account => {
      oracles.push(account); //To keep the server updated with oracles addresses 
                                  //Because sometimes the oracle is already registered in the contract from before, 
                                  //so it reverts when the server tries to register it again.
      flightSuretyApp.methods.registerOracle().send({
            "from": account,
            "value": fee,
            "gas": 4712388,
            "gasPrice": 100000000000
      }).then(result => {
          //oracle created;
          console.log('Registered: '+account);
      }).catch(err => {
          // oracle errored
          console.log('Could not create oracle at address: '+account+'\n\tbecause: '+err);
      })
    }); //end forEach account

    // Display oracles addresses and indexes previously retrieved from smart contract
    oracles.forEach(oracle => {
      flightSuretyApp.methods
          .getMyIndexes().call({
            "from": oracle,
            "gas": 4712388,
            "gasPrice": 100000000000
          }).then(result => {
            console.log('Assigned Indices: '+result[0]+', '+result[1]+', '+result[2]+'\tfor oracle: '+oracle);

          }).catch(error => {
            console.log('Could not retrieve oracle indices because: '+error);
          })

    }); //end forEach oracle

    console.log('Oracles server all set-up...\nOracles registered and assigned addresses...');
    console.log('Listening to a request event...');
  //Listen for oracleRequest event
  flightSuretyApp.events.OracleRequest({
    fromBlock: "latest"
  }, function(error, event) {
    
    console.log('Caught an event: '+event);
  });

  }).catch(err=>{console.log('Could not retrieve registration fee. '+err)});//end REGISTRATION_FEE 
});//end getAccounts

  
const app = express();
app.get('/api', (req, res) => {
    res.send({
      message: 'An API for use with your Dapp!'
    })
})

export default app;

