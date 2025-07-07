// DRF employing AMF
// In this version I used 1 / ds which simplified calculations

pragma solidity ^0.5.13;

contract Faucet{

//	State variables
	uint constant nore = 2;
	uint constant userQuota = 10;
	uint es = userQuota * 2;
	uint[nore][2] er;
	uint[nore][2] r;
	uint p = 1000000;

	address owner;
	uint offset;
	uint k;
	uint[2] mds;
	uint[nore][2] crd;
	uint[2] nod;
	uint nou;
	uint e = 1;
	uint resetEpoch;
	
	struct User{
		address payable userAddress;
		uint ce;
		uint de;
		uint[nore] balance;
		uint[nore][2] d;
		uint[2] ds;
	}

	mapping(address => uint) registered;
	mapping(uint => User) userList;


	constructor() public {
		owner = msg.sender;
		offset = block.number + 1;
		for(uint i = 0; i < nore; i++){
			er[0][i] = 150 * userQuota;
			er[1][i] = 150 * userQuota;
			r[0][i] = 150 * userQuota;
			r[0][i] = 150 * userQuota;
		}
	}

/*
	constructor(uint[] memory resourceCapacities) public {
	    owner = msg.sender;
	    offset = block.number + 1;
	for(uint i = 0; i < nore; i++){
		er[i] = resourceCapacities[i];
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
//	Update e & round: e starts from 1 to prevent triggering "already demanded" in the first e
		if(e < (block.number - offset) / es + 1){
			e = (block.number - offset) / es + 1;
			uint8 selector = uint8((e) % 2);
			for(uint i = 0; i < nore; i++)
				r[1 - selector][i] = er[1 - selector][i] + r[1 - selector][i];
	
			k = (r[selector][0] * mds[selector] * p) / crd[selector][0];
			for(uint i = 0; i < nore; i++)
				if(k > (r[selector][i] * mds[selector] * p) / crd[selector][i])
					k = (r[selector][i] * mds[selector] * p) / crd[selector][i];
		}
	
	}	


	function demand(uint[nore] memory _amount) public{
//	Regular checks and updates
		updateState();
		require(registered[msg.sender] != 0, "Your address has not been registered.");
		uint8 selector = uint8((e + 1) % 2);
	    	User storage user = userList[registered[msg.sender]];
		require(user.de < e, "You have already made a demand in this epoch.");

// 	Register demand
		for(uint i = 0; i < nore; i++)
			user.d[selector][i] = _amount[i];

//	Find and register the dominant share
		uint temp = (r[selector][0] * p) / user.d[selector][0];
		for(uint i = 0; i < nore; i++)
			if(temp > (r[selector][i] * p) / user.d[selector][i])
				temp = (r[selector][i] * p) / user.d[selector][i];
	
		user.ds[selector] = temp;
		
//	Update user demand epoch
		user.de = e;
	
//	Systemwide updates
		if(resetEpoch < e){
			for(uint i = 0; i < nore; i++)
				crd[selector][i] = _amount[i] *  temp;
			mds[selector] = temp;
			resetEpoch = e;
		}            
	
		else{
			for(uint i = 0; i < nore; i++)
				crd[selector][i] += _amount[i] * temp;
			if(mds[selector] < temp)
				mds[selector] = temp;
		}
	}

	function claim() public{
//	Regular checks and updates
		updateState();
		require(registered[msg.sender] != 0, "Your address has not been registered.");
		uint8 selector = uint8(e % 2);
		User storage user = userList[registered[msg.sender]];
		require(user.ce < e, "You have already claimed your share in this epoch.");

// 	Caculate and assign the (partial) share
		uint ratio = (user.ds[selector] * p) / mds[selector];
		uint share;
	
		for(uint i = 0; i < nore; i++){
			share = ((k * ratio) / (p * p)) * user.d[selector][i];
			user.balance[i] += share;
			r[selector][i] -= share;
		}

//	Update user claim epoch
		user.ce = e;
	}

	function viewBalance(uint _user) view public returns(uint[nore] memory) {
		return userList[_user].balance;
	} 

	function viewShare() view public returns(uint) {
		return k;
	} 

	function viewDemand(uint _user) view public returns(uint[nore] memory) {
		uint selector = (e + 1) % 2;
		uint[nore] memory value = userList[_user].d[selector];
		return value;
	}

	function viewCumDemand(uint e) view public returns(uint[nore] memory) {
		return crd[e];
	}

	function viewDominantShare(uint _user, uint func) view public returns(uint) {
		uint selector = (e + func) % 2;
		return userList[_user].ds[selector];
	}

	function viewMaxDominantShare(uint e) view public returns(uint) {
		return mds[e];
	}

	function viewCapacity(uint e) view public returns(uint[nore] memory) {
		return r[e];
	}

        function viewNumberOfDemands(uint e) view public returns(uint) {
                return nod[e];
        }

}
