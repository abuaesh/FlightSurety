pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
//import "./FlightSuretyData.sol"; //No need for raw import since an interface to the data contract is added to the end

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {
    using SafeMath for uint256; // Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)
    FlightSuretyData flightSuretyData;  //Instantiate a variable of the data contract to access its methods;
                                        //Another approach that will save you gas, is to create an interface to the data contract here
    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    // Flight status codes
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;

    address private contractOwner;          // Account used to deploy contract

    bool private operational = true;

    uint M = 2;                        //Minimum number of votes to perform critical operations
                                        //(eg. register an airline, change operational status); used for multi-sig consensus.
                                    //Registration of fifth and subsequent airlines requires multi-party consensus of 50% of registered airlines
                                    //So, the first value used for M is 2: 50% of 4 airlines.
                                    //M will be updated by  registerAirline function as the number of registering flights changes
    address[] private multiCallsReg = new address[](0);   //Array used to store voting addresses on registering a new airline.
    address[] private multiCallsOp = new address[](0);   //Array used to store voting addresses on changing operational mode of the contract.

    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;
        address airline;
   }
    mapping(bytes32 => Flight) private flights;


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
         // Modify to call data contract's status
        require(isOperational(), "Contract is currently not operational");
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

    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/

    /**
    * @dev Contract constructor
    *
    */
    constructor
                                (
                                    address dataContract
                                )
                                public
    {
        contractOwner = msg.sender;
        flightSuretyData = FlightSuretyData(dataContract);        // now flightSuretyData has the expected methods
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/
    function setDataContractAddress
                                (
                                    address dataContract
                                )
                                external
                                requireContractOwner
    {
        flightSuretyData = FlightSuretyData(dataContract);
    }
    function isOperational()
                            public
                            view //pure
                            returns(bool)
    {
        return operational;  // Modify to call data contract's status
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
                            returns(bool success, uint votes)
    {
        require(mode != operational, "Operational status already set to given mode");
        require(msg.sender == contractOwner || flightSuretyData.canVote(msg.sender), "Message sender cannot vote on changing operational mode");
        if(flightSuretyData.RegisteredAirlinesCount() < 4 ) //Multi-party Consensus does not apply yet
        {
            require(msg.sender == contractOwner, "Only contract owner can change the mode at this time"); //Only contract owner can change op mode
            operational = mode;
            return(true, 0);
        }

        bool isDuplicate = false;

            for(uint c = 0; c < multiCallsOp.length; c++)
            {
                if(multiCallsOp[c] == msg.sender)
                {
                    isDuplicate = true;
                    break;
                }
            }

            require(!isDuplicate, "Caller already voted on changing operational mode");

            multiCallsOp.push(msg.sender);

            votes = multiCallsOp.length;

            if(votes >= M)      //Voting threshold reached -> Change operational mode
            {
                operational = mode;
                multiCallsOp = new address[](0);      //Reset list of voters
                success = true;
            }

        return(success, votes);
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *
    */
    function registerAirline
                            (
                                address airline
                            )
                            external
                            //This function changes state but does not take fees: non-payable (which is the default)
                            requireIsOperational()
                            returns(bool success, uint256 votes)
    {
        require(flightSuretyData.isRegistered(airline) == false, "This airline is already registered.");
        require(flightSuretyData.canVote(msg.sender), "This airline did not provide funding in order to vote on adding new airlines");

        if(flightSuretyData.RegisteredAirlinesCount() < 4) //Multi-party Consensus does not apply yet
        {
            flightSuretyData.registerAirline(airline);
            success = true;
            votes = 0;
        }
        //Otherwise (M>=4), apply multisig:
        //require(flightSuretyData.canVote(msg.sender), "Message sender is not authorized to register a new airline.");
        else{
            bool isDuplicate = false;

            for(uint c = 0; c < multiCallsReg.length; c++)
            {
                if(multiCallsReg[c] == msg.sender)
                {
                    isDuplicate = true;
                    break;
                }
            }

            require(!isDuplicate, "Caller already voted on adding this flight");

            multiCallsReg.push(msg.sender);

            votes = multiCallsReg.length;

            if(votes >= M)      //Voting threshold reached -> Register the airline
            {
                flightSuretyData.registerAirline(airline);
                multiCallsReg = new address[](0);      //Reset list of voters
                success = true;
                //Update M to be 50% of registered airlines
                M = flightSuretyData.RegisteredAirlinesCount();
                M = M.div(2);
            }
        } //end else

        return (success, votes);
    }


   /**
    * @dev Register a future flight for insuring.
    *
    */
    function registerFlight
                                (
                                    string flight
                                )
                                external
                                //view //pure
                                requireIsOperational()
    {
        // 1. Convert flight name from string to bytes32
        string memory newFlight = flight;
        bytes32 Flight;
        assembly {
            Flight := mload(add(newFlight, 32)) //convert flight name from string to bytes32
        }
        // 2. Ensure the flight is not already insured
        require(!flights[Flight].isRegistered, 'This flight is already registered');
        //3. Register the new flight
        flights[Flight].isRegistered = true;
        flights[Flight].statusCode = STATUS_CODE_UNKNOWN;
        //flights[Flight].airline = msg.sender;
        //Update the timestamp and airlines somehow...
    }

   /**
    * @dev Called after oracle has updated flight status
    *
    */
    function processFlightStatus
                                (
                                    address airline,
                                    string memory flight,
                                    uint256 timestamp,
                                    uint8 statusCode
                                )
                                internal
                                view //pure
                                requireIsOperational()
    {
        // 1. Convert flight name from string to bytes32
        string memory newFlight = flight;
        bytes32 theFlight;
        assembly {
            theFlight := mload(add(newFlight, 32)) //convert flight name from string to bytes32
        }
        require(flights[theFlight].airline == airline,
                    'Trying to register new flight status, but airlines do not match');
        flights[theFlight].statusCode = statusCode;
        flights[theFlight].updatedTimestamp = timestamp;
    }


    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus
                        (
                            address airline,
                            string flight,
                            uint256 timestamp
                        )
                        external
                        requireIsOperational()
    {
        uint8 index = getRandomIndex(msg.sender);

        // Generate a unique key for storing the request
        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        oracleResponses[key] = ResponseInfo({
                                                requester: msg.sender,
                                                isOpen: true
                                            });

        emit OracleRequest(index, airline, flight, timestamp);

    }
// region INSURANCE PURCHASE MANAGEMENT

/**
    * @dev Allow a user to buy insurance
    *
    */
    function buyInsurance
                            (
                                string inFlight
                            )
                            external
                            payable
                            requireIsOperational()
    {

        // 1. Convert flight name from string to bytes32
        string memory inFlight2 = inFlight;
        bytes32 flight;
        assembly {
            flight := mload(add(inFlight2, 32)) //convert flight name from string to bytes32
        }

        // 2. Ensure the flight exists in the supported flights
        require(flights[flight].isRegistered, 'This flight is not registered for insurance');

        // 3. Check insurance amount is less than 1 ether and more than 0:
        require(msg.value <= 1 ether && msg.value > 0, 'You must pay an insurance amount up to 1 ether.');
        //4. Forward call to the desired function in the data contract: buy or fund
            //buy keeps the funds in the app contract, while fund forwards the funds to the data contract
        //flightSuretyData.buy(msg.sender, flight, msg.value);
        flightSuretyData.fund.value(msg.value)(msg.sender, flight);
        //Always use fund, since the refund will always happen from the data contract

    }

    /**
    * @dev Allow a user to view the list of flights they  insured
    *
    */
    function viewInsuredFlights
                            (
                            )
                            external
                            returns(bytes32[] memory insuredFlights)
    {
        //bytes32[] memory insuredF;
        insuredFlights = flightSuretyData.viewInsuredFlights(msg.sender);
        //insuredFlights = insuredF;
        //return(, amounts);
    }

    event  payout(uint amount, address insuree);


    function claimInsurance
                            (
                                string flight1
                            )
                            external
    {
         // 1. Convert flight name from string to bytes32
        string memory flight2 = flight1;
        bytes32 flight;
        assembly {
            flight := mload(add(flight2, 32)) //convert flight name from string to bytes32
        }

        // 2. Ensure the flight exists in the supported flights
        require(flights[flight].isRegistered, 'This flight is not registered for insurance');

        flights[flight].statusCode = STATUS_CODE_LATE_AIRLINE; //for testing only

        // 3. Ensure the flight status is one that implies refund -> STATUS_CODE_LATE_AIRLINE = 20
        require(flights[flight].statusCode == STATUS_CODE_LATE_AIRLINE, 'Flight status does not imply insurance refunding');

        // 4. Forward call to data contract for refund
        flightSuretyData.creditInsurees(flight, msg.sender);

        //5. Emit event for the frontend to allow user to withdraw if they want
        //emit payout(credit, msg.sender);
    }

    function getCredit
                        (

                        )
                        external
                        view
                        returns(uint credit)
    {
        credit = flightSuretyData.getCredit(msg.sender);
    }
    function withdrawCredit
                            (
                            )
                            public
                            payable
    {
        flightSuretyData.pay(msg.sender);
    }
//end region

// region ORACLE MANAGEMENT

    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;


    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester;                              // Account that requested status
        bool isOpen;                                    // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses;          // Mapping key is the status code reported
                                                        // This lets us group responses and identify
                                                        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(address airline, string flight, uint256 timestamp, uint8 status);

    event OracleReport(address airline, string flight, uint256 timestamp, uint8 status);

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(uint8 index, address airline, string flight, uint256 timestamp);

    // Register an oracle with the contract
    function registerOracle
                            (
                            )
                            external
                            payable
                            requireIsOperational()
    {
        // Block multiple registrations of the same oracle
        require(oracles[msg.sender].isRegistered == false, "Oracle already registered");
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({
                                        isRegistered: true,
                                        indexes: indexes
                                    });
    }

    function getMyIndexes
                            (
                            )
                            external
                            view
                            returns(uint8[3] memory)
    {
        require(oracles[msg.sender].isRegistered, "Not registered as an oracle");

        return oracles[msg.sender].indexes;
    }




    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse
                        (
                            uint8 index,
                            address airline,
                            string flight,
                            uint256 timestamp,
                            uint8 statusCode
                        )
                        external
                        requireIsOperational()
    {
        require((oracles[msg.sender].indexes[0] == index) ||
                (oracles[msg.sender].indexes[1] == index) ||
                (oracles[msg.sender].indexes[2] == index), "Index does not match oracle request");


        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        require(oracleResponses[key].isOpen, "Either flight, timestamp or index do not match oracle request");

        oracleResponses[key].responses[statusCode].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        emit OracleReport(airline, flight, timestamp, statusCode);
        if (oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES) {

            //Found the flight status -- oracles reached the consensus
            emit FlightStatusInfo(airline, flight, timestamp, statusCode);

            // Handle flight status as appropriate
            processFlightStatus(airline, flight, timestamp, statusCode);
        }
    }


    function getFlightKey
                        (
                            address airline,
                            string storage flight,
                            uint256 timestamp
                        )
                        internal
                        pure
                        returns(bytes32)
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes
                            (
                                address account
                            )
                            internal
                            returns(uint8[3] storage indexes)
    {
        //uint8[3] storage indexes;
        indexes[0] = getRandomIndex(account);
        indexes[1] = indexes[0];
        while(indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex
                            (
                                address account
                            )
                            internal
                            returns (uint8)
    {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), account))) % maxValue);

        if (nonce > 250) {
            nonce = 0;  // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

// endregion

}



//Add the interface of the data contract

contract FlightSuretyData{
    function isOperational() public view returns(bool);
    function setOperatingStatus(bool mode) external;
    function isRegistered(address airline) external view returns(bool);
    function canVote(address airline) external view returns(bool);
    function RegisteredAirlinesCount() external view returns(uint);
    function registerAirline(address airline) external;
    function enableVoting() external payable;
    function buy(address customer, bytes32 flight, uint amount) external payable;
    function viewInsuredFlights(address customer) external returns(bytes32[] memory insuredFlights);
    function creditInsurees(bytes32, address) external view returns(uint credit);
    function getCredit(address)external view returns(uint credit);
    function pay(address) public;
    function fund(address, bytes32) public payable;
    function getFlightKey(address airline, string memory flight, uint256 timestamp) internal pure returns(bytes32);
    function() external payable;
}

