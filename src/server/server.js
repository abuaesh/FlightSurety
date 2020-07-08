
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
    console.log('Smart Contract requires ('+fee+') wei to fund oracle registration.');
    for(var a = FIRST_ORACLE_ADDRESS;a<ORACLES_COUNT;a++)
    {
      let account = accounts[a];
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
          //console.log('Registered: '+account);
      }).catch(err => {
          // oracle errored
          //console.log('Could not create oracle at address: '+account+'\n\tbecause: '+err);
      })
    } //end for loop

    // Display oracles addresses and indexes previously retrieved from smart contract
   /* oracles.forEach(oracle => {
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

    }); //end forEach oracle*/

    console.log('Oracles server all set-up...\nOracles registered and assigned addresses...');
    console.log('Listening to a request event...');

  //Listen for oracleRequest event
   //1. Fires only once at the first emittance of the event
  /*flightSuretyApp.once('OracleRequest', (error,event)=>{
    if(error) console.log(error)    ;
    console.log('Listened to the new oracle event. Returned this event: ');
    console.log(event['returnValues']);
      });
  //*/
  //2. Returns all events--filtered by the first parameter
  /*flightSuretyApp.getPastEvents('OracleRequest', {fromBlock: 'latest'},
    function(error,events){}).then(function(error, events){ 
      if(error) console.log(error);
      console.log('Caught an event: ');
      console.log(events); });
  //*/

   //3. Returns all events
  /*flightSuretyApp.events.allEvents()
    .on('data', (event) => {
      console.log(event);
    })
    .on('error', console.error);
  //*/
  
  /* //4. Same as above
  flightSuretyApp.events.allEvents({fromBlock: 'latest'}, 
        function(error, event){
          if(error) console.log(error);
          console.log('Caught an event: ');
          console.log(events);
        });
  //*/
  
   //5.
  flightSuretyApp.events.OracleRequest({fromBlock: 'latest'}, 
    function(error, event) {
      if(error) console.log(error);
      console.log('Caught an event: ');
      let result = event['returnValues'];
      console.log(result);
      let index = result['index'];
      let airline = result['airline'];
      let flight = result['flight'];
      let timestamp = result['timestamp']; //In real-life scenarios, 
                                          //timestamp is needed to determine flight status near timestamp
                                          //But it will be ignored here since this is just a simulation.
      console.log('Only the oracles with index '+index+' should respond to the request.');

      //Query the oracles with matching index for the flight status
      oracles.forEach(oracle => {
        flightSuretyApp.methods
            .getMyIndexes().call({
              "from": oracle,
              "gas": 4712388,
              "gasPrice": 100000000000
            }).then(result => {
              console.log('Indices: '+result[0]+', '+result[1]+', '+result[2]+'\tfor oracle: '+oracle);
              if(result[0]==index || result[1]==index || result[2]==index) //matching oracle -> respond with random status
              {
                let flightStatus = 10 * Math.floor(Math.random() * 6);        /* Flight status codes
                                                                    STATUS_CODE_UNKNOWN = 0;
                                                                    STATUS_CODE_ON_TIME = 10;
                                                                    STATUS_CODE_LATE_AIRLINE = 20;
                                                                    STATUS_CODE_LATE_WEATHER = 30;
                                                                    STATUS_CODE_LATE_TECHNICAL = 40;
                                                                    STATUS_CODE_LATE_OTHER = 50;*/
                console.log('Oracle hit... Responding with random flight status...'+flightStatus);                                                    
                //Reply back to smart contract with the determined status code
                /*flightSuretyApp.methods
                .submitOracleResponse(index, airline,flight, timestamp, flightStatus).send({
                  "from": oracle,
                  "gas": 4712388,
                  "gasPrice": 100000000000
                }).then(result => {
                  //Do nothing? 
                });//end submitOracleResponse*/
              }//forEach oracle
  
            }).catch(error => {
              console.log('Could not retrieve oracle indices because: '+error);
            })
  
      }); //end forEach oracle
    });
  //*/

  }).catch(err=>{console.log('Could not retrieve registration fee. '+err)});//end REGISTRATION_FEE 
});//end getAccounts

  
const app = express();
app.get('/api', (req, res) => {
    res.send({
      message: 'An API for use with your Dapp!'
    })
})

export default app;

