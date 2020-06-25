import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';

var BigNumber = require('bignumber.js');

export default class Contract {
    constructor(network, callback) {

        let config = Config[network];
        this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
        this.initialize(callback);
        this.owner = null;
        this.airlines = [];
        this.passengers = [];
    }

    initialize(callback) {
        this.web3.eth.getAccounts((error, accts) => {
           
            this.owner = accts[0];
            //this.owner = '0xFEA8e051Bf37bd55a1C41D40B1167409C26B1E3b';

            let counter = 1;
            
            while(this.airlines.length < 5) {
                this.airlines.push(accts[counter++]);
            }

            while(this.passengers.length < 5) {
                this.passengers.push(accts[counter++]);
            }

            callback();
        });
    }

    isOperational(callback) {
       let self = this;
       self.flightSuretyApp.methods
            .isOperational()
            .call({ from: self.owner}, callback);
    }

    fetchFlightStatus(flight, callback) {
        let self = this;
        let payload = {
            airline: self.airlines[0],
            flight: flight,
            timestamp: Math.floor(Date.now() / 1000)
        } 
        self.flightSuretyApp.methods
                .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
                .call({ from: self.owner}, callback);

        //console.log('From outside the promise: result is: ' + JSON.stringify(result));
            
    }

    buyInsurance(flight, amount, callback) {
        let self = this;
        let payload = {
            flight: flight,
            amount: amount
        } 
        amount *= Math.pow(10, 18);         //convert amount from ethers to wei
        self.flightSuretyApp.methods
            .buyInsurance(payload.flight)
            .send({ from: self.owner, value: amount}, (error, result) => {
                callback(error, payload);
            });
    }

    /*viewInsuredFlights(callback) {
        let self = this;
        
        self.flightSuretyApp.methods
            .viewInsuredFlights()
            .call({from: self.owner}, callback);
    }*/

    claimInsurance(flight, callback){
        let self = this;

        self.flightSuretyApp.methods
            .claimInsurance(flight)
            .send({from: self.owner}, callback);
    }

    getCredit(callback){
        let self = this;

        self.flightSuretyApp.methods
        .getCredit()
        .call({from: self.owner}, callback);
    }
            
        
        /* Could not find the correct code for listening to the emitted event
        var payoutEvent = self.flightSuretyApp.payout();
        payoutEvent.watch((error, result) => {
            result /= Math.pow(10, 18); //convert from wei back to ether
            callback(error, result)}
            );*/
    

    withdraw(callback){
        let self = this;
        //credit *= (new BigNumber(10)).pow(18);         //convert amount from ethers to wei
        self.flightSuretyApp.methods
        .withdrawCredit()
        .send({from: self.owner, gas: Config.gas}, callback);
    }

    registerFlight(flight, callback) {
        let self = this;

        self.flightSuretyApp.methods
        .registerFlight(flight).send({from: this.airlines[0]}, (error, result) => {
            callback(error, flight);
        });
    }
}