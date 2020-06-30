
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');

contract('Flight Surety Tests', async (accounts) => {

  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

  it(`(multiparty) has correct initial isOperational() value`, async function () {

    // Get operating status
    let status = await config.flightSuretyData.isOperational.call({ from: config.flightSuretyApp.address });
    assert.equal(status, true, "Incorrect initial operating status value");

  });

  it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

      // Ensure that access is denied for non-Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false, { from: config.testAddresses[2] });
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, true, "Access not restricted to Contract Owner");
            
  });

  it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

      // Ensure that access is allowed for Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false);
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, false, "Access not restricted to Contract Owner");
      
  });

  it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

    if(await config.flightSuretyData.isOperational.call()) //Make sure the contract is already operational before toggling it to flase
      await config.flightSuretyData.setOperatingStatus(false);

      let reverted = false;
      try 
      {
          await config.flightSuretyData.setTestingMode(true); //fallback function will be called
      }
      catch(e) {
          reverted = true;
      }
      assert.equal(reverted, true, "Access not blocked for requireIsOperational");      

      // Set it back for other tests to work
      await config.flightSuretyData.setOperatingStatus(true);

  });

  it('(airline) can register an Airline using registerAirline() if it is funded', async () => {
    
    if(!(await config.flightSuretyData.isOperational())) //if the contract is not operational, make it operational
      await config.flightSuretyData.setOperatingStatus(true);
    // ARRANGE
    let newAirline = accounts[2];
    //var funds = (new BigNumber(10)).pow(19) ; // 10 ethers     //web3.utils.toWei( '10', 'ether') //web3.toWei(10,'ether');
    //await config.flightSuretyData.enableVoting({from: config.firstAirline, value: funds});

    // ACT
    try {
        await config.flightSuretyApp.registerAirline(newAirline, {from: config.firstAirline});
    }
    catch(e) {

    }
    let result = await config.flightSuretyData.isRegistered.call(newAirline); 

    // ASSERT
    assert.equal(result, true, "Airline should be able to register another airline if it has provided funding");
    //assert.equal(await config.flightSuretyData.canVote.call(config.firstAirline), true, "Airline should be able to vote if it has provided funding");

  });

  it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {
    
    if(!(await config.flightSuretyData.isOperational())) //if the contract is not operational, make it operational
      await config.flightSuretyData.setOperatingStatus(true);
    // ARRANGE
    let newAirline = accounts[3];

    // ACT
    try {
      //accounts[2] was already registered in the previous test but is not yet funded,
      //so it shoulfd not be able to register a new airline
        await config.flightSuretyApp.registerAirline(newAirline, {from: accounts[2]}); //should fail
    }
    catch(e) {

    }
    let result = await config.flightSuretyData.isRegistered.call(newAirline); 

    // ASSERT
    assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");

  });
 
  it('Fifth and subsequent airlines should be registered if a consensus of 50% of registered airlines is reached', async () => {
    
    if(!(await config.flightSuretyData.isOperational())) //if the contract is not operational, make it operational
      await config.flightSuretyData.setOperatingStatus(true);
    // ARRANGE

    //1. Assign addresses to airlines:
    let airline2 = accounts[2];
    let airline3 = accounts[3];
    let airline4 = accounts[4];
    let newAirline = accounts[5]; //to be registered by consensus
    
    //2. Register new airlines
    //await config.flightSuretyApp.registerAirline(airline2, {from: config.firstAirline}); 
    //console.log('\nairline1 is registered: ', await config.flightSuretyData.isRegistered.call(config.firstAirline));//registered from config file
    //console.log('\nairline2 is registered: ', await config.flightSuretyData.isRegistered.call(airline2));//already registered from previous test
    await config.flightSuretyApp.registerAirline(airline3, {from: config.firstAirline});
    //console.log('\nairline3 is registered: ', await config.flightSuretyData.isRegistered.call(airline3));
    await config.flightSuretyApp.registerAirline(airline4, {from: config.firstAirline});
    //console.log('\nairline4 is registered: ', await config.flightSuretyData.isRegistered.call(airline4));

    //3. Enable new airlines to vote
    var funds = (new BigNumber(10)).pow(19); //10 ethers  
    //console.log('\nairline1 is funded: ', await config.flightSuretyData.canVote.call(config.firstAirline)); //funded in the previous test
    await config.flightSuretyData.enableVoting({from: airline2, value: funds});
    //console.log('\nairline2 is funded: ', await config.flightSuretyData.canVote.call(airline2));
    await config.flightSuretyData.enableVoting({from: airline3, value: funds});
    //console.log('\nairline3 is funded: ', await config.flightSuretyData.canVote.call(airline3));
    await config.flightSuretyData.enableVoting({from: airline4, value: funds});
    //console.log('\nairline4 is funded: ', await config.flightSuretyData.canVote.call(airline4));
    
    // ACT
    await config.flightSuretyApp.registerAirline(newAirline, {from: airline3});
    //console.log('\nAirline1 vote- success:', result[0], '\tvotes:', result[1]);
    await config.flightSuretyApp.registerAirline(newAirline, {from: airline4});
    //console.log('\nAirline3- succuess:', result[0], '\tvotes:', result[1]);
    //await config.flightSuretyApp.registerAirline(newAirline, {from: airline4});
    //console.log('\nAirline4- succuess:', result[0], '\tvotes:', result[1]);

    result = await config.flightSuretyData.isRegistered.call(newAirline); 

    // ASSERT
    assert.equal(result, true, "Fifth (and subsequent) airlines should  be registered if a 50% consensus is reached");
  });
  it('Fifth (and above) airlines should not be registered if less than 50% voted', async () => {
    
    if(!(await config.flightSuretyData.isOperational())) //if the contract is not operational, make it operational
      await config.flightSuretyData.setOperatingStatus(true);
    // ARRANGE

    //1. Assign addresses to airlines:
    let airline2 = accounts[2];
    let airline3 = accounts[3];
    let airline4 = accounts[4];
    let newAirline = accounts[6]; //to be registered by consensus
    
    //2. Register new airlines
    //Done in previous test

    //3. Enable new airlines to vote
    //Done in previous test
    
    // ACT
    await config.flightSuretyApp.registerAirline(newAirline, {from: airline3});
    //await config.flightSuretyApp.registerAirline(newAirline, {from: airline4});

    result = await config.flightSuretyData.isRegistered.call(newAirline); 

    // ASSERT
    assert.equal(result, false, "Fifth (and above) airlines should not be registered if less than 50% voted");
  });
});
