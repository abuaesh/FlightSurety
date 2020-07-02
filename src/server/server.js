/*import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';
import express from 'express';
*/
import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';

export default class OraclesServer {
  constructor(network, callback) {
    // Define workspace variables
    let config = Config[network];
    //this.web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws')));
    this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
    this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
    //this.web3.eth.defaultAccount = this.web3.eth.accounts[0];
    //this.flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
    this.oracles = [];
    this.initialize(callback);
    this.ORACLES_COUNT = 0;
  }

  initialize(callback){
    this.web3.eth.getAccounts((error, accounts) => {
      // Register 20 oracles
      this.ORACLES_COUNT = 15;
      this.FIRST_ORACLE_ADDRESS = this.web3.eth.accounts.length - this.ORACLES_COUNT;
      this.LAST_ORACLE_ADDRESS = this.ORACLES_COUNT + this.FIRST_ORACLE_ADDRESS;
      // Initialize oracles addresses and indexes with smart contract
      this.flightSuretyApp.REGISTRATION_FEE.call((err, fee)=>{
        console.log(fee);
        for(let a=this.FIRST_ORACLE_ADDRESS; a<this.LAST_ORACLE_ADDRESS; a++) {      
          this.flightSuretyApp.registerOracle({from: accounts[a], value: fee},()=>{
            this.oracles.push(accounts[a]);
            console.log(accounts[a]);
          });

        }
      });
    });
  }//end initialize

  oraclesCount(callback){
    console.log('oracles count is called.. Returning '+ this.ORACLES_COUNT);
    callback(this.ORACLES_COUNT);
  }

}//end Server
 
 
 /*
  

// Display oracles addresses and indexes previously retrieved from smart contract
for(let a=FIRST_ORACLE_ADDRESS; a<ORACLES_COUNT+FIRST_ORACLE_ADDRESS; a++) {  
    let result = await flightSuretyApp.getMyIndexes.call({from: accounts[a]});
    message = `Oracle Registered: ${result[0]}, ${result[1]}, ${result[2]}`;
    console.log(message);
  }
}
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

  const app = express();
    app.get('/api', (req, res) => {
      console.log('Server running...');
        res.send({
          message: 'An API for use with your Dapp!'
        })
    })

  export default app;
  
*/