pragma solidity ^0.4.24;

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
    //bytes32[] flightNames; //a list of insured flights for each customer
    //uint[] amounts; // holds insurance amounts for each insured flight in wei
    mapping(bytes32 => uint) insuranceDetails; //stores how much did the customer insure for each flight
    bytes32[] insuranceKeys; //used to search the above mapping--e.g. to view all insured flights
    }

    mapping(address => insuredFlights) allInsuredFlights;
    mapping(address => uint) payouts; //Amounts owed to insurees but have not yet been credited to their accounts
                                        //These will be credited to the insurees when they initiate a withdrawal.
    //event  payout(uint amount, address insuree); //This contract is not directly connected to the frontend, no need for events here.
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
        require(allInsuredFlights[customer].insuranceDetails[flight] == 0, 'This flight is already insured by this customer');

        // 2. Accept insurance:
        allInsuredFlights[customer].insuranceDetails[flight] = amount;
        allInsuredFlights[customer].insuranceKeys.push(flight);
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
                            returns(bytes32[] memory)
    {
        return( allInsuredFlights[customer].insuranceKeys);
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                    bytes32 flight,
                                    address insuree
                                )
                                external
                                requireIsOperational
                                //Apply Re-entrancy Gaurd Here(not required by project)
                                //requireAuthorizedCaller
                                returns(uint credit) //This is a state-changing function, so it cannot return a value
                                //We will inform caller of the credit amount by emitting an event
    {
        //1. Checks
        credit = allInsuredFlights[insuree].insuranceDetails[flight];
        require(credit > 0,
                'You either did not insure this flight from before, or you have already claimed the credit for this flight.');

        //2. Effects
            //2.a Update the insurance information in your mapping
            allInsuredFlights[insuree].insuranceDetails[flight] = 0;
            //2.b Calculate the amount the customer must be refunded: 1.5 time the insurance amount
            credit = credit.mul(3);
            credit = credit.div(2);
        require(allInsuredFlights[insuree].insuranceDetails[flight] == 0, 'Could not payout your credit');
        //3. Interaction
        payouts[insuree] = payouts[insuree].add(credit);
        require(payouts[insuree] > 0, 'Unable to add your credit to the payout system');
        //web3.js is not connected to this contract, you need to emit from the app contract
        //just return the tuples and the app contract should do the emit back to the front end
        //emit payout(credit, insuree);
        //Next: when the emitted event is caught in the frontend, allow user to withdraw amount -> withdraw button should appear
    }


    function getCredit
                        (
                            address insuree
                        )
                        external
                        view
                        returns(uint credit)
    {
        credit = payouts[insuree];
        return credit;
    }
    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                                address insuree
                            )
                            public
                            requireIsOperational
                            //requireAuthorizedCaller
    {
        uint credit = payouts[insuree];
        //1. Checks
        require(credit > 0, 'User does not have credit to withraw');
        //2. Effects
        payouts[insuree] = 0; //reset credit to prevent multiple withrawal of the same credit
        require(payouts[insuree] == 0, 'Could not withdraw credit');
        //3. Interaction
        msg.sender.transfer(credit);
        //msg.sender.call.value(credit)("");
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */
    function fund
                            (
                                address insuree,
                                bytes32 flight
                            )
                            external
                            payable
                            requireIsOperational
                            //requireAuthorizedCaller
    {
        // 1. Check the customer did not insure this flight previously:
        require(allInsuredFlights[insuree].insuranceDetails[flight] == 0, 'This flight is already insured by this customer');
        // 2. Accept insurance:
        allInsuredFlights[insuree].insuranceDetails[flight] = msg.value;
        //allInsuredFlights[insuree].insuranceKeys.push(flight);  //to be able to show the customer later all the flights he insured
        //feature not required and needs to be fixed later.
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
        //fund();
    }


}

