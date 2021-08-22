loadScript("abifile.js") 
loadScript("binfile.js") 

Contract  = web3.eth.contract(conabi) ;
personal.unlockAccount(eth.accounts[0],"", null) ;
contract = Contract.new("DISQUALIFIED!",{from: eth.accounts[0], data: conobj, gas: 8000000});
console.log(eth.getTransactionReceipt(contract.transactionHash).contractAddress);
