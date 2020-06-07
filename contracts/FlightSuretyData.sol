pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    struct Airline{
        bytes name;
        bool isRegistered;
        bool canVote;
    }
    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false
    mapping(address => Airline) private airlines;                       //Airlines are contract accounts, so we represent them as addresses.
                                                                        //Another approach can be to make a struct Airline. But let's keep it simple.
    uint256 private airlinesCount;                                   //The number of registered airlines.
    mapping(address => bool) private authorizedCallers;             //Used to keep track of which app contracts can access this contract
    uint M =2;      //Voting threshold, starts when there are at least 4 registered airlines
    address[] private multiCallsOp  = new address[](0);    //List of voters on changing the operational mode
    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (
                                    address firstAirline
                                )
                                public
    {
        contractOwner = msg.sender;
        airlines[firstAirline].isRegistered = true;      //Project Specification: First airline is registered when contract is deployed.
        airlines[firstAirline].canVote = false;    //First airline must provide funding before it can vote for others to join
        airlinesCount = 1;
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational()
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    /**
    * @dev Modifier that requires the calling contract to be in the "authorizedCallers" list
    *      This is used on all functions(except those who are called by the contract owner)
    *       to ensure that only the authorized app contracts gain access to the data on this contract
    */
    modifier requireAuthorizedCaller()
    {
        require(authorizedCallers[msg.sender], "Caller is not authorized");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Sets which app contracts can access this data contract
    *
    * This method is used to authorize a FlightSuretyApp contract to interact with FlightSuretyData.
    * You can use it to change which FlightSuretyApp is active. But it is not required
    */
    function authorizeCaller
                            (
                                address appContract
                            )
                            external
                            requireContractOwner
                            requireIsOperational
    {
        authorizedCallers[appContract] = true;
    }

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */
    function isOperational()
                            public
                            view
                            //requireAuthorizedCaller
                            returns(bool)
    {
        return operational;
    }

    /**
    * @dev Checks if an airline can vote
    *
    *       Airlines are assumed to be smart contracts, so they are represented here as addresses to contract accounts.
    */
    function canVote
                            (
                                address airline
                            )
                            external
                            view //pure
                            requireIsOperational
                            //requireAuthorizedCaller
                            returns(bool)
    {
        return (airlines[airline].canVote);
    }
    /**
    * @dev Does the voting work for multisignature functions
    * Keeps track of voting responses,
    * and returns true if the voting threshold is rechead so the caller function can perform the task
    */
    function vote(address voter)
            private
            returns(bool success)
    {
        require(voter == contractOwner || airlines[voter].canVote, "This address cannot vote.");
        success = false;
        bool isDuplicate = false;

            for(uint c = 0; c < multiCallsOp.length; c++)
            {
                if(multiCallsOp[c] == voter)
                {
                    isDuplicate = true;
                    break;
                }
            }

            require(!isDuplicate, "Caller already voted on changing operational mode");

            multiCallsOp.push(voter);

            uint votes = multiCallsOp.length;

            if(votes >= M)      //Voting threshold reached -> Change operational mode
            {
                multiCallsOp = new address[](0);      //Reset list of voters
                success = true;
            }

        return(success);
    }

    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */
    function setOperatingStatus
                            (
                                bool mode
                            )
                            external
                            //requireContractOwner
    {
        require(mode != operational, "Operational status already set to given mode");
        
        if(airlinesCount < 4) //Voting threshold not reached yet
        {
            require(msg.sender == contractOwner, "Message sender is not allowed to change the operational mode of the contract");
            operational = mode;

        }
        else
            if(vote(msg.sender))
                operational = mode;
    }

     /**
    * @dev Checks if an airline is already registered
    *      Can only be called from FlightSuretyApp contract
    *
    *       Airlines are assumed to be smart contracts, so they are represented here as addresses to contract accounts.
    */
    function isRegistered
                            (
                                address airline
                            )
                            external
                            view //pure
                            requireIsOperational
                            //requireAuthorizedCaller
                            returns(bool)
    {
        return (airlines[airline].isRegistered);
    }

 /**
    * @dev Returns the number of registered airlines
    *
    */
    function RegisteredAirlinesCount
                            (
                            )
                            external
                            view //pure
                            //requireIsOperational  //OK to reveal the count even if contract is not operational
                            //requireAuthorizedCaller
                            returns(uint)
    {
        return (airlinesCount);
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    *       Airlines are assumed to be smart contracts, so they are represented here as addresses to contract accounts.
    */
    function registerAirline
                            (
                                address airline
                            )
                            external
                            //view //pure
                            requireIsOperational
                            //requireAuthorizedCaller
    {
        //require(airlines[airline].isRegistered == false, "This airline is already registered"); //App contract already checks it.
        airlines[airline].isRegistered = true;
        airlines[airline].canVote = false;

        airlinesCount++;
    }

    /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    *       Airlines are assumed to be smart contracts, so they are represented here as addresses to contract accounts.
    */
    function enableVoting
                            (
                            )
                            external
                            payable//view //pure
                            requireIsOperational
                            //requireAuthorizedCaller
    {
        require(airlines[msg.sender].canVote == false, "This airline already can vote");
        require(airlines[msg.sender].isRegistered, "This airline is not registered");
        require(msg.value >= 10 ether, "Not enough funds to enable voting for this airline");
        airlines[msg.sender].canVote = true;
        require(airlines[msg.sender].canVote, "Failed to enable voting!");
    }


   /**
    * @dev Buy insurance for a flight
    *
    */
    struct insuredFlights{
    bytes32[] flightNames; //a list of insured flights for each customer
    uint[] amounts; // holds insurance amounts for each insured flight in wei
    }

    mapping(address => insuredFlights) allInsuredFlights;

    function buy
                            (
                                address customer,
                                bytes32 flight,
                                uint amount
                            )
                            external
                            //payable   //The fees are kept in the app contract
                            requireIsOperational
                            //requireAuthorizedCaller
    {
        
        // 1. Check the customer did not insure this flight previously:
        bool alreadyInsured = false;

        if(allInsuredFlights[customer].flightNames.length > 0) //Customer has insured some flights from before
        {
            for(uint i = 0; i < (allInsuredFlights[customer].flightNames).length; i++)
                if((allInsuredFlights[customer].flightNames)[i] == flight)
                    alreadyInsured = true;
        }
        else    //First time this customer insures a flight -> instantiate their insured flights array
        {
            allInsuredFlights[customer].flightNames = new bytes32[] (0);
            allInsuredFlights[customer].amounts = new uint[] (0);
        }
        require(!alreadyInsured,'You already insured this flight.');

        // 2. Accept insurance:
        allInsuredFlights[customer].flightNames.push(flight);
        allInsuredFlights[customer].amounts.push(amount);   //This line is probably the one causing the error!

    }

    /**
    * @dev Allow a user to view the list of flights they  insured
    *
    */
    function viewInsuredFlights
                            (
                                address customer
                            )
                            external
                            returns(bytes32[] memory, uint[] memory)
    {
        return( allInsuredFlights[customer].flightNames,
                allInsuredFlights[customer].amounts);
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                )
                                external
                                view //pure
                                requireIsOperational
                                //requireAuthorizedCaller
    {
    }

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                            )
                            external
                            view //pure
                            requireIsOperational
                            //requireAuthorizedCaller
    {
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */
    function fund
                            (
                            )
                            public
                            payable
                            requireIsOperational
                            //requireAuthorizedCaller
    {
    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        internal
                        pure
                        returns(bytes32)
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function()
                            external
                            payable
                            requireIsOperational
                            //requireAuthorizedCaller
    {
        fund();
    }


}

