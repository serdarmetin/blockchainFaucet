//----------- A Number of Functions For Testing Heap Performance-------------


//Corrects a parity bug : cause last transaction to enter block 
function dummytx() {
 	personal.unlockAccount(eth.accounts[0],"",null) ;
	eth.sendTransaction({from: eth.accounts[0], to: eth.accounts[0],value: 1}) ;
	return(true) ; 

}

//Unlocks the admin account
function myunlock() {
	personal.unlockAccount(eth.accounts[0],"",null) ;
	return(true) ; 
}


//Loops "iterations" times and pushes a random number to the heap defined in "abifile.js"
function pushtest(iterations) {
	eth.defaultAccount=eth.accounts[0]
	personal.unlockAccount(eth.accounts[0],"",null) ; 

	loadScript("abifile.js") ; 
	contractaddr = "0x46662e22d131ea49249e0920c286e1484feef76e"  ;
	contractobj = web3.eth.contract(contractabiobj).at(contractaddr);

	total = 0.0 ; 
	for(i=0 ; i < iterations ; i++) {
		personal.unlockAccount(eth.accounts[0],"",null) ; 
		rndnumber =  Math.floor((Math.random() * 10) + 1) ;    // between 1 and 10    
		userid =  Math.floor((Math.random() * 100) + 1) ;    // between 1 and 100
		x = contractobj.push(rndnumber,userid,{gas:8000000}) ;
		y = eth.getTransactionReceipt(x) ;
		total += y.gasUsed ;
	}
  dummytx() ; 
  console.log(total/iterations) ;
  return(true) ; 
}

//Loops "iterations" times and pops from the heap defined in "abifile.js"
function poptest(iterations) {
	eth.defaultAccount=eth.accounts[0]
	personal.unlockAccount(eth.accounts[0],"",null) ; 	

	loadScript("abifile.js") ; 
	contractaddr = "0x46662e22d131ea49249e0920c286e1484feef76e"  ;
	contractobj = web3.eth.contract(contractabiobj).at(contractaddr);

	total = 0.0 ; 
	for(i=0 ; i < iterations ; i++) {
		personal.unlockAccount(eth.accounts[0],"",null) ; 
		x = contractobj.pop() ;
		y = eth.getTransactionReceipt(x) ;
		total += y.gasUsed ;
	}
  dummytx() ; 
  console.log(total/iterations) ;
  return(true) ; 
}


