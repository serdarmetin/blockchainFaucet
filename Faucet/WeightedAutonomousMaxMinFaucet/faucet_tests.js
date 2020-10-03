//----------- A Number of Functions For Testing Weighted Autonomous Max-min Faucet Performance-------------

contractaddr = "0x713C2364e73cCE1440c34cdADdC2C9f9c0405AC5";

loadScript("abifile.js");
contractobj = web3.eth.contract(contractabiobj).at(contractaddr);

function dummytx(iterations) {
	personal.unlockAccount(eth.accounts[0],"", null) ;
	for(i = 0; i < iterations; i++){
		eth.sendTransaction({from: eth.accounts[0], to: eth.accounts[0],value: 1}) ;
	}
	return(true);
}

//Unlocks  account i
function unlock(i) {
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

function registerAccounts(from, to){
 	eth.defaultAccount = eth.accounts[0];
	personal.unlockAccount(eth.accounts[0],"",null) ;
	for(i = from; i <= to; i++){
		contractobj.registerUser(eth.accounts[i]);
	}
	return(true);
}


//Creates demands from user, to user, in the interval [floor, floor+range]
function makeDemands(from, to, floor, range){

	for(i = from; i <= to; i++){
 	        eth.defaultAccount = eth.accounts[i];
		personal.unlockAccount(eth.accounts[i],"",null);
		randomNumber = Math.floor((Math.random() * range) + floor);
		transaction = contractobj.demand(randomNumber);        //transaction hash
		receipt = eth.getTransactionReceipt(transaction);      //transaction receipt
		console.log(randomNumber, receipt.gasUsed);
	}
	return(true);
}

function makeClaims(from, to){

	for(i = from; i <= to; i++){
 	        eth.defaultAccount = eth.accounts[i];
		personal.unlockAccount(eth.accounts[i],"",null);
		transaction = contractobj.claim();        //transaction hash
		balance = contractobj.viewBalance(i);
		receipt = eth.getTransactionReceipt(transaction);      //transaction receipt
		console.log(balance, receipt.gasUsed);
	}
	return(true);
}

numberOfUsers = 500;
floor = 10;
range = 20;

registerAccounts(1,numberOfUsers);
dummytx(2*numberOfUsers );
for(j = 0; j < 3; j++){
        makeDemands(1,numberOfUsers,floor,range);
	for(k = 0; k < 3; k++)
        	makeClaims(1,numberOfUsers);
}

