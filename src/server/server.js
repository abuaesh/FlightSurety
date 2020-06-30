import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';
import express from 'express';

async () => {
  // Define workspace variables
  let config = Config['localhost'];
  let web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws')));
  web3.eth.defaultAccount = web3.eth.accounts[0];
  let flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);

  // Register 20 oracles
  const TEST_ORACLES_COUNT = 20;
  const FIRST_ORACLE_ADDRESS = web3.eth.accounts.length - TEST_ORACLES_COUNT;

  let fee = await flightSuretyApp.REGISTRATION_FEE.call();

  for(let a=FIRST_ORACLE_ADDRESS; a<TEST_ORACLES_COUNT+FIRST_ORACLE_ADDRESS; a++) {      
    await flightSuretyApp.registerOracle({from: accounts[a], value: fee});
    let result = await flightSuretyApp.getMyIndexes.call({from: accounts[a]});
    console.log(`Oracle Registered: ${result[0]}, ${result[1]}, ${result[2]}`);
  }

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
      res.send({
        message: 'An API for use with your Dapp!'
      })
  })

export default app;

