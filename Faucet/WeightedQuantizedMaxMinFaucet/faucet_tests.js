//----------- A Number of Functions For Testing Quantized Max-min Faucet Performance-------------

loadScript("deploy.js");
contractobj = web3.eth.contract(conabi).at(eth.getTransactionReceipt(contract.transactionHash).contractAddress);
console.log(eth.getTransactionReceipt(contract.transactionHash).contractAddress);
console.log(eth.getTransactionReceipt(contract.transactionHash).gasUsed);


/*
loadScript("abifile.js");
contractAddress = "0x4f871223294567e70b8aece24b3032a2bb48fcee";
contractobj = web3.eth.contract(conabi).at(contractAddress);
*/

numberOfUsers = 1000;
floor = 1;
range = 250;
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
		randomNumber = Math.floor((Math.random() * 10) + 1);
		contractobj.registerUser(eth.accounts[i], randomNumber);
		console.log(contractobj.viewWeight(i));
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
		transaction = contractobj.claim({gas:8000000});        //transaction hash
		balance = contractobj.viewBalance(i);
		refund  = contractobj.viewRefund(i);
		receipt = eth.getTransactionReceipt(transaction);      //transaction receipt
		console.log(balance, receipt.gasUsed, refund, receipt.gasUsed - refund);
	}
	return(true);
}

runTests();

