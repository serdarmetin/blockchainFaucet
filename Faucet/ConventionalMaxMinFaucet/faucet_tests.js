//----------- A Number of Functions For Testing Conventional Max-Min Faucet Performance-------------


contractaddr = "0x32b3fC1bC7aa3FdE06e7B4aB72c3BDF5f88d0f0a";
loadScript("abifile.js") ;
contractobj = web3.eth.contract(contractabiobj).at(contractaddr);

//Corrects a parity bug : cause last transaction to enter block 
function dummytx() {
 	personal.unlockAccount(eth.accounts[0],"", null) ;
	eth.sendTransaction({from: eth.accounts[0], to: eth.accounts[0],value: 1}) ;
	return(true) ; 

}

//Unlocks the admin account
function myunlock() {
	personal.unlockAccount(eth.accounts[0],"",null) ;
	return(true) ; 
}

function createNewAccounts(numberOfAccounts){
	for(i = 0; i < numberOfAccounts; i++){
	personal.newAccount("");
	}	
}

function unlockAccounts(numberOfAccounts){
	for(i = 1; i < numberOfAccounts; i++){
	personal.unlockAccount(eth.accounts[i],"",null) ;
	}
	return(true);
}

function registerAccount(accountNumber){
 	eth.defaultAccount = eth.accounts[0];
	personal.unlockAccount(eth.accounts[0],"",null) ;
	contractobj.registerUser(eth.accounts[accountNumber]);
}

function registerAccounts(from, to){
 	eth.defaultAccount = eth.accounts[0];
	personal.unlockAccount(eth.accounts[0],"",null) ;
	for(i = from; i <= to; i++){
		contractobj.registerUser(eth.accounts[i]);
	}
	return(true);
}

function makeDemands(from, to){

	for(i = from; i <= to; i++){
 	        eth.defaultAccount = eth.accounts[i];
		personal.unlockAccount(eth.accounts[i],"",null);
		randomNumber = Math.floor((Math.random() * 20) + 1);
		transaction = contractobj.demand(randomNumber);        //transaction hash
		receipt = eth.getTransactionReceipt(transaction);      //transaction receipt
		console.log(i, randomNumber);
	}
	return(true);
}

function distribute(){
        eth.defaultAccount = eth.accounts[0];
        personal.unlockAccount(eth.accounts[0],"",null);
	transaction = contractobj.distribute();
	receipt = eth.getTransactionReceipt(transaction);
	return(receipt.status);
}
