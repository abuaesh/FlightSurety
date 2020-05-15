var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "bar raccoon unfold vivid hill truly cage decide broken blush mechanic knife";

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",     // Localhost
      port: 8545,            // Standard Ganache UI port
      network_id: "*", 
      gas: 4600000
    },  
    //They say replacing the below code with the above one will solve the nonce problem, let's try
    //Update: Indeed it does work now!
      /*provider: function() {
        return new HDWalletProvider(mnemonic, "http://127.0.0.1:8545/", 0, 50);
      },
      network_id: '*',
      gas: 6700000
    }*/
  },
  compilers: {
    solc: {
      version: "^0.4.24"
    }
  }
};