
import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';


(async() => {

    let result = null;

    let contract = new Contract('localhost', () => {

        // Read transaction
        contract.isOperational((error, result) => {
            console.log(error,result);
            display('Operational Status', 'Check if contract is operational', [ { label: 'Operational Status', error: error, value: result} ]);
        });

        // Airline registers Flights
        DOM.elid('register-flight').addEventListener('click', () => {
            let flight = DOM.elid('new-flight').value;
            if(flight != '')
            {
                //Forward call to smart contract
                contract.registerFlight(flight, (error, result) => {
                    display('Register Flight', 'Trigger App contract', [ { label: 'Registration:', error: error,  value: 'Success - registered. ' } ]);
                });
            }
            
        });
    
        // User buys insurance
        DOM.elid('buy-insurance').addEventListener('click', () => {
        // Get User address from Metamask
        if (!contract.owner) {
            alert("You need to install and login to an Ethereum-compatible wallet or extension like MetaMask to use this dApp.");
            //return false; //Do something to abort the process?
        }
        else{ //Proceed to buy insurance under the user's account
            let flight = DOM.elid('flight-number').value;
            let amount = DOM.elid('insurance-value').value;
            if(confirm('You are about to pay '+ amount +' Ethers for insuring your trip on flight '+flight+'. The amount will be deducted from the account: ' + contract.owner + '.\nAre you sure?'))
            {                    
                //Forward call to smart contract
                contract.buyInsurance(flight, amount, (error, result) => {
                    display('Buy Insurance', 'Trigger App contract', [ { label: 'Buying result:', error: error,  value: 'Success - insured ' + result.flight + ' with ' + result.amount + ' ethers.'} ]);
                    //Display updated list of all insured flights for this customer
                   /* contract.viewInsuredFlights((error2, result2) => {
                        console.log('Flight insured successfully. Here is the updated list of your insured flights transactions:\n');
                        //for(var i=0; i<result[0].length; i++)
                            //console.log(result[0][i] + '\t' + result[1][i] + ' ethers\n');
                        console.log(JSON.stringify(result2));
                    });*/
                });

            }

        }
            
        });

        // User-submitted transaction
        DOM.elid('submit-oracle').addEventListener('click', () => {
            let flight = DOM.elid('flight-number').value;
            // Write transaction
            contract.fetchFlightStatus(flight, (error, result) => {
                display('Oracles', 'Trigger oracles', [ { label: 'Fetch Flight Status', error: error, value: JSON.stringify(result)} ]);
                //console.log('fetchFlightStatus in contract.js returned error: ' + error);
                //console.log('fetchFlightStatus in contract.js returned result: ' + result);
            });
        });


        // User-submitted transaction
        DOM.elid('claim-insurance').addEventListener('click', () => {
            let flight = DOM.elid('flight-number-claim').value;
            // Write transaction
            contract.claimInsurance(flight, (error, result) => {
                display('Insurance Amount', 
                    'You are legible to a refund for flight '+flight, 
                    [ { label: 'Refund amount in Ether:', 
                        error: error, 
                        value: JSON.stringify(result),
                        credit: result
                    } ]);
                console.log('fetchFlightStatus in contract.js returned error: ' + error);
                console.log('fetchFlightStatus in contract.js returned result: ' + result);
                
            });
        });


        // User-submitted transaction
        DOM.elid('withdraw-credit').addEventListener('click', () => {
            console.log('Withdraw button was clicked!');
        });
    
    });
    

})();

function withdraw(){
    console.log('withdraw function called!');
}

function getAccounts(callback) {
    web3.eth.getAccounts((error,result) => {
        if (error) {
            console.log(error);
        } else {
            callback(result);
        }
    });
}

function display(title, description, results) {
    let displayDiv = DOM.elid("display-wrapper");
    let section = DOM.section();
    section.appendChild(DOM.h2(title));
    section.appendChild(DOM.h5(description));
    results.map((result) => {
        let row = section.appendChild(DOM.div({className:'row'}));
        row.appendChild(DOM.div({className: 'col-sm-4 field'}, result.label));
        row.appendChild(DOM.div({className: 'col-sm-8 field-value'}, result.error ? String(result.error) : String(result.value)));
        if(result.credit)
            row.appendChild(DOM.div({className: 'col-sm-4 field-value'},  
            DOM.button('Withdraw', {type:'button', value: 'Withdraw', name:'withdraw-credit'})));

        section.appendChild(row);
    })
    displayDiv.append(section);

}







