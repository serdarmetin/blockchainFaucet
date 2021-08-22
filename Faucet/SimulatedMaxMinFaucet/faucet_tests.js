//----------- A Number of Functions For Testing Simulated Max-min Faucet Performance-------------


loadScript("deploy.js");
contractobj = web3.eth.contract(conabi).at(eth.getTransactionReceipt(contract.transactionHash).contractAddress);
console.log(eth.getTransactionReceipt(contract.transactionHash).contractAddress);
console.log(eth.getTransactionReceipt(contract.transactionHash).gasUsed);

numberOfUsers = 250;

floor = 15;
range = 20;
times = 3;

function runTests(){
	registerAccounts(1,numberOfUsers);
	for(j = 0; j < times; j++){
        	makeDemands(1,numberOfUsers,floor,range);
        	makeClaims(1,numberOfUsers);
	}
}

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
		balance = contractobj.viewBalance(i);
		transaction = contractobj.claim({gas : 8000000});        //transaction hash
		refund  = contractobj.viewRefund(i);
		receipt = eth.getTransactionReceipt(transaction);      //transaction receipt
                console.log(contractobj.viewBalance(i) - balance, receipt.gasUsed, refund, receipt.gasUsed - refund);

	}
	return(true);
}

runTests();
