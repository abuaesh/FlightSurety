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
    uint256 public airlinesCount;                                   //The number of registered airlines.
    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (
                                )
                                public
    {
        contractOwner = msg.sender;
        airlines[msg.sender].isRegistered = true;      //Project Specification: First airline is registered when contract is deployed.
        airlines[msg.sender].canVote = true;            //TODO: Update later with an airline address
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

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */
    function isOperational()
                            public
                            view
                            returns(bool)
    {
        return operational;
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
                            requireContractOwner
    {
        require(mode != operational, "Operational status already set to given mode");
        require(msg.sender == contractOwner, "Message sender is not allowed to change the operational mode of the contract");
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
                            requireIsOperational()
                            returns(bool)
    {
        return (airlines[airline].isRegistered);
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
                            requireIsOperational()
                            returns(bool)
    {
        return (airlines[airline].canVote);
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
                            requireIsOperational()
    {
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
                            requireIsOperational()
    {
        require(airlines[msg.sender].isRegistered, "This airline is not registered");
        require(msg.value >= 10 ether, "Not enough funds to enable voting for this airline");
        airlines[msg.sender].canVote = true;
    }


   /**
    * @dev Buy insurance for a flight
    *
    */
    function buy
                            (
                            )
                            external
                            payable
                            requireIsOperational()
    {

    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                )
                                external
                                view //pure
                                requireIsOperational()
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
                            requireIsOperational()
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
                            requireIsOperational()
    {
    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
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
                            requireIsOperational()
    {
        fund();
    }


}

