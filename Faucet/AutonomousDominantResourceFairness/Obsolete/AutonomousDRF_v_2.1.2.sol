// DRF employing AMF

pragma solidity ^0.5.13;

contract Faucet{

//	State variables
	uint constant nore = 2;
	uint constant userQuota = 10;
	uint es = userQuota * 2;
	uint[nore][2] ec;
	uint[nore][2] lc;
	uint[nore][2] c;
	uint p = 1000000;

	address owner;
	uint offset;
	uint k;
	uint[nore][2] crd;
	uint[2] nod;
	uint nou;
	uint epoch = 1;
	uint resetEpoch;
	
	struct User{
	    address payable userAddress;
	    uint ce;
	    uint cr;
	    uint[2] de;
	    uint[nore] balance;
	    uint[nore][2] d;
	uint saturated;
	uint[2][2] ds; // 0 for amount 1 for type
	}

	mapping(address => uint) registered;
	mapping(uint => User) userList;


	constructor() public {
	    owner = msg.sender;
	    offset = block.number + 1;
	for(uint i = 0; i < nore; i++){
		ec[0][i] = 1500;
		ec[1][i] = 1500;
		c[0][i] = 1500;
		lc[0][i] = 1500;
		}
	}

/*
	constructor(uint[] memory resourceCapacities) public {
	    owner = msg.sender;
	    offset = block.number + 1;
	for(uint i = 0; i < nore; i++){
		ec[i] = resourceCapacities[i];
		}
	}
*/

	function depositMoney() public payable{
	    require(msg.sender == owner, "Only the owner can deposit money to the contract.");
	}

	function withdrawMoney(address payable _to, uint _amount, uint _resourceType) public {
	    User storage user = userList[registered[msg.sender]];
	    require(_amount<= user.balance[_resourceType], "You do not have enough funds.");
	    user.balance[_resourceType] -= _amount;
	    _to.transfer(_amount);
 }


	function registerUser(address payable _user) public {
	    require (msg.sender == owner, "You have to be the owner of the contract in order to call this function.");
	    require (registered[_user] == 0, "The user has already been registered.");
	    require (nou <= userQuota, "There is no room for new users.");
	    nou++;
	    registered[_user] = nou;
	    userList[registered[_user]].userAddress = _user;
	}


/*
	This is the function to update the global state of the system
	which is called at the beginning of "demand" and "claim" functions.
	It is responsible for the synchronisation of Epochs and Rounds,
	and replenishment of the resources according to the variable "ec"
*/

	function updateState() private {
//	Update epoch & round: epoch starts from 1 to prevent triggering "already d" in the first epoch
		if(epoch < (block.number - offset) / es + 1){
			epoch = (block.number - offset) / es + 1;
			uint8 selector = uint8((epoch) % 2);
			for(uint i = 0; i < nore; i++){
				c[1 - selector][i] = ec[1 - selector][i] + lc[1 - selector][i];
				lc[1 - selector][i] = c[1 - selector][i];
			}
	
		k = (c[selector][0] * p * p) / crd[selector][0];
		for(uint i = 0; i < nore; i++){
			if(k > (c[selector][i] * p * p) / crd[selector][i])
				k = (c[selector][i] * p * p)  / crd[selector][i];
		}

	}
	
	}	


	function demand(uint[nore] memory _amount) public{
//	Regular checks and updates
		updateState();
		require(registered[msg.sender] != 0, "Your address has not been registered.");
		uint8 selector = uint8((epoch + 1) % 2);
	    	User storage user = userList[registered[msg.sender]];
		require(user.de[selector] < epoch, "You have already made a demand in this epoch.");

// 	Register demand
		for(uint i = 0; i < nore; i++){
		user.d[selector][i] = _amount[i];
		}

//	Find and register the dominant share
		uint[2] memory temp;
		for(uint i = 0; i < nore; i++){
			if(temp[0] < abs2percent(user.d[selector][i], i, selector)){
				temp[0] = abs2percent(user.d[selector][i], i, selector);
				temp[1] = i;
			}
		}
	
		user.ds[selector][0] = temp[0];
		user.ds[selector][1] = temp[1];
		
//	Update user demand epoch
		user.de[selector] = epoch;
	
//	Systemwide updates
		if(resetEpoch < epoch){
//			nod[selector] = 1;
			for(uint i = 0; i < nore; i++){
				crd[selector][i] = _amount[i] * p / temp[0];
			}
			resetEpoch = epoch;
		}            
	
		else{
			for(uint i = 0; i < nore; i++)
				crd[selector][i] += _amount[i] * p / temp[0];
		}
	}

	function claim() public{
//	Regular checks and updates
	   updateState();
	   require(registered[msg.sender] != 0, "Your address has not been registered.");
	   uint8 selector = uint8(epoch % 2);
	   User storage user = userList[registered[msg.sender]];
	   if(user.saturated == epoch) return;

// 	Calculate and assign the (partial) share
	   uint ratio = p / user.ds[selector][0];
	   uint share;
	
	   for(uint i = 0; i < nore; i++){
		   share = ((k * ratio) / (p * p)) * user.d[selector][i];
		   user.balance[i] += share;
		   lc[selector][i] -= share;
	   }
	}

	function abs2percent(uint value, uint resourceType, uint selector) view private returns(uint) {
		return (value * p)  / c[selector][resourceType];
	}

	function percent2abs(uint value, uint resourceType, uint selector) view private returns(uint) {
		return (value * c[selector][resourceType]) / p;
	} 

	function viewBalance(uint _user) view public returns(uint[nore] memory) {
		return userList[_user].balance;
	} 

	function viewShare() view public returns(uint) {
		return k;
	} 

	function viewDemand(uint _user) view public returns(uint[nore] memory) {
		uint selector = (epoch + 1) % 2;
		uint[nore] memory value = userList[_user].d[selector];
		return value;
	}

	function viewCumDemand(uint e) view public returns(uint[nore] memory) {
		return crd[e];
	}

	function viewDominantShare(uint _user, uint func) view public returns(uint) {
		uint selector = (epoch + func) % 2;
		return userList[_user].ds[selector][0];
	}

	function viewCapacity(uint e) view public returns(uint[nore] memory) {
		return c[e];
	}

        function viewNumberOfDemands(uint e) view public returns(uint) {
                return nod[e];
        }

	function viewLeftoverCapacity(uint e) view public returns(uint[nore] memory) {
		return lc[e];
	}
}
