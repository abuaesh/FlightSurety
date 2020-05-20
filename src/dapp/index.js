
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
    
        // User buys insurance
        DOM.elid('buy-insurance').addEventListener('click', () => {
        // Get User address from Metamask
        if (!contract.owner) {
            alert("You neeed to install and login to an Ethereum-compatible wallet or extension like MetaMask to use this dApp.");
            //return false; //Do something to abort the process?
        }
        else{ //Proceed to buy insurance under the user's account
            let flight = DOM.elid('flight-number').value;
            let insuranceValue = DOM.elid('insurance-value').value;
            if(confirm('You are about to pay '+ insuranceValue +' Ethers for insuring your trip on flight '+flight+'. The amount will be deducted from the account: ' + contract.owner + '.\nAre you sure?'))
            {    
                console.log(contract.owner);
                    //display('Buy Insurance', 'Buying insurance for account: '+account, [ { label: 'Fetch Flight Status', error: error, value: result} ]);
                
                    
                    //contract.fetchFlightStatus(flight, (error, result) => {
                    //display('Oracles', 'Trigger oracles', [ { label: 'Fetch Flight Status', error: error, value: result.flight + ' ' + result.timestamp} ]);
                //});
            }

        }
            
        });

        // User-submitted transaction
        DOM.elid('submit-oracle').addEventListener('click', () => {
            let flight = DOM.elid('flight-number').value;
            // Write transaction
            contract.fetchFlightStatus(flight, (error, result) => {
                display('Oracles', 'Trigger oracles', [ { label: 'Fetch Flight Status', error: error, value: result.flight + ' ' + result.timestamp} ]);
            });
        })
    
    });
    

})();

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
        section.appendChild(row);
    })
    displayDiv.append(section);

}







