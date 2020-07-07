/*
import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';
import express from 'express';


let config = Config['localhost'];
let web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws')));
web3.eth.defaultAccount = web3.eth.accounts[0];
let flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);

const ORACLES_COUNT = 15;
const FIRST_ORACLE_ADDRESS = web3.eth.accounts.length - ORACLES_COUNT;
const LAST_ORACLE_ADDRESS = ORACLES_COUNT + FIRST_ORACLE_ADDRESS;
console.log('There will be '+ ORACLES_COUNT+' oracles.');
// Initialize oracles addresses and indexes with smart contract
console.log('The last oracle has the address: '+ LAST_ORACLE_ADDRESS);

flightSuretyApp.methods.getRegistrationFee().call((error,result) => { 
  console.log(reult);
  for(let a=FIRST_ORACLE_ADDRESS; a<LAST_ORACLE_ADDRESS; a++) {      
    flightSuretyApp.methods.registerOracle().send({from: accounts[a], value: result},()=>{
      //oracles.push(accounts[a]);
      console.log(accounts[a]);
    });
  }//end for
});//end REGISTRATION_FEE


flightSuretyApp.events.OracleRequest({
    fromBlock: 0
  }, function (error, event) {
    if (error) console.log(error)
    console.log(event)
});

const app = express();
app.get('/api', (req, res) => {
    res.send({
      message: 'An API for use with your Dapp!'
    })
    console.log('halo..');
})

export default app;

/*import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';
import express from 'express';
*/

import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';
import express from 'express';

class OraclesServer {
  constructor(network) {
    // Define workspace variables
    let config = Config[network];
    this.web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws')));
    //this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
    this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
    //this.web3.eth.defaultAccount = this.web3.eth.accounts[0];
    //this.flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
    this.oracles = [];
    this.initialize();
    //this.ORACLES_COUNT = 0;
  }

  initialize(){
    this.web3.eth.getAccounts().then(accounts => {
      // Register 20 oracles
      this.ORACLES_COUNT = 20;
      this.FIRST_ORACLE_ADDRESS = accounts.length - this.ORACLES_COUNT -1;
      this.LAST_ORACLE_ADDRESS = this.ORACLES_COUNT + this.FIRST_ORACLE_ADDRESS;
      console.log('Ganache returned '+accounts.length+' accounts.');
      console.log('Server will use only '+this.ORACLES_COUNT+' of these accounts for oracles.');
      console.log('Starting from accounts['+this.FIRST_ORACLE_ADDRESS+'] for the first oracle.');
      console.log('Ending at accounts['+this.LAST_ORACLE_ADDRESS+'] for the last oracle.');

      // Initialize oracles addresses and indexes with smart contract
      this.flightSuretyApp.methods.REGISTRATION_FEE().call((fee) => { 
        fee = Math.pow(10, 18); //See why registration fee is not being retrieved from smart contract
        console.log('Smart Contract requires (' +fee+') ethers to fund oracle registration.');
        accounts.forEach(account => {
          this.oracles.push(account); //To keep the server updated with oracles addresses 
                                      //Because sometimes the oracle is already registered in the contract from before, 
                                      //so it reverts when the server tries to register it again.
          this.flightSuretyApp.methods.registerOracle().send({
                "from": account,
                "value": 1000000000000000000,
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
      
        this.displayOracles();
        this.listenForRequests();
      });//end REGISTRATION_FEE 
    });//end getAccounts
    
  }//end initialize

  oraclesCount(callback){
    console.log('oraclesCount is called from server. Responding..\n There are '+ this.ORACLES_COUNT+' registered oracles.');
    callback(this.ORACLES_COUNT);
  }

  displayOracles(){
    // Display oracles addresses and indexes previously retrieved from smart contract
    this.oracles.forEach(oracle => {
      this.flightSuretyApp.methods
          .getMyIndexes().call({
            "from": oracle
          }).then(result => {
            console.log('Assigned Indices: '+result[0]+', '+result[1]+', '+result[2]+'\t--for oracle: '+oracle);
          }).catch(error=>{
            console.log('Could not retrieve oracle indices because: '+error);
          });
    }); //end forEach oracle
    
    console.log('Oracles server all set-up... ');
  }//end displayOracles
  
  listenForRequests()
  {
    console.log('Listening to a request event...');
    //Listen for oracleRequest event
    this.flightSuretyApp.events.OracleRequest({
      fromBlock: "latest"
    }, function (error, event) {
      if (error) {
          console.log(error);
      }
      console.log(event);
    });
    /*this.flightSuretyApp.once('OracleRequest', event => {
      console.log('Listened to the new oracle request event. Returned: '+event+' Event.');
    });*/
  }

}//end OraclesServer Class

  /////////////////////////////////////////////////////////////////////////////////////////
  /*
    

    // Listen to requests for oracles
    flightSuretyApp.events.OracleRequest({
        fromBlock: 0
      }, function (error, event) {
        if (error) console.log(error)
        console.log(event)
    }).on('data', function(event){
      console.log(event); // same results as the optional callback above
      console.log('Listened to the Orace Request..')
    })
    .on('changed', function(event){
      // remove event from local database

    })
    .on('error', console.error);

    
  };
*/
    // Instantiate oracles server:
      let oraclesServer = new OraclesServer('localhost'); 
      oraclesServer.displayOracles();

  const app = express();
    app.get('/api', (req, res) => {
        res.send({
          message: 'An API for use with your Dapp!'
        })
    })

  export default app;
  
