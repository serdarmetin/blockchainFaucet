// DRF employing AMF
//TODO Adjust floating point arithmetics

pragma solidity ^0.5.13;

contract Faucet{

//	State variables
	uint constant numberOfResources = 2;
	uint roundSpan = 10;
	uint epochSpan = roundSpan * 4;
	uint[numberOfResources][2] epochCapacity;
	uint[numberOfResources][2] leftoverCapacity;
	uint[numberOfResources][2] capacity;
	uint percentCapacity;
	uint precision = 1000000;

	address owner;
	uint offset;
	uint unitShare;
	uint[2] maxDominantShare;
	uint[2] cumDominantShare;
	uint[2] numberOfDemands;
	uint numberOfUsers;
	uint epoch = 1;
	uint round = 4;
	uint resetEpoch;
	
	struct User{
	    address payable userAddress;
	    uint claimEpoch;
	    uint claimRound;
	    uint[2] demandEpoch;
	    uint[numberOfResources] balance;
	    uint[numberOfResources][2] demanded;
	uint[2] saturated;
	uint[2][2] dominantShare; // 0 for amount 1 for type
	}

	mapping(address => uint) registered;
	mapping(uint => User) userList;


	constructor() public {
	    owner = msg.sender;
	    offset = block.number + 1;
	for(uint i = 0; i < numberOfResources; i++){
		epochCapacity[i] = 150;
		}
	}

/*
	constructor(uint[] memory resourceCapacities) public {
	    owner = msg.sender;
	    offset = block.number + 1;
	for(uint i = 0; i < numberOfResources; i++){
		epochCapacity[i] = resourceCapacities[i];
		}
	}
*/

	function depositMoney() public payable{
	    require(msg.sender == owner, "Only the owner can deposit money to the contract.");
	}

	function withdrawMoney(address payable _to, uint _amount, uint _resourceType) public {
	    require(_amount<= userList[registered[msg.sender]].balance[_resourceType], "You do not have enough funds.");
	    userList[registered[msg.sender]].balance[_resourceType] -= _amount;
	    _to.transfer(_amount);
 }


	function registerUser(address payable _user) public {
	    require (msg.sender == owner, "You have to be the owner of the contract in order to call this function.");
	    require (registered[_user] == 0, "The user has already been registered.");
	    numberOfUsers++;
	    registered[_user] = numberOfUsers;
	    userList[registered[_user]].userAddress = _user;
	}


/*
	This is the function to update the global state of the system
	which is called at the beginning of "demand" and "claim" functions.
	It is responsible for the synchronisation of Epochs and Rounds,
	and replenishment of the resources according to the variable "epochCapacity"
*/


	function updateState() private {
	    //Update epoch & round: epoch starts from 1 to prevent triggering "already demanded" in the first epoch
	    if(epoch < (block.number - offset) / epochSpan + 1){
	        epoch = (block.number - offset) / epochSpan + 1;
	        round = ((block.number - offset) % epochSpan) / roundSpan + 1;
	    for(uint i = 0; i < numberOfResources; i++){
	        	capacity[selector][i] = epochCapacity[selector][i] + leftoverCapacity[selector][i];
		leftoverCapacity[selector][i] = capacity[selector][i];
	        }

	        uint8 selector = uint8(epoch % 2);
	    unitShare = precision / (cumDominantShare / (maxDominantShare * numberOfDemands[selector]));

	    }

//	Epoch is up-to-date, so update only the round: round also starts from 1 to prevent triggering "already claimed" in the first round
	    else if(round != ((block.number - offset) % epochSpan) / roundSpan + 1){
	        round = ((block.number - offset) % epochSpan) / roundSpan + 1;

	        uint8 selector = uint8(epoch % 2);
	    if(numberOfDemands[selector] > 0)
	    	unitShare = precision / (cumDominantShare / (maxDominantShare * numberOfDemands[selector]));
	    }
	}


	function demand(uint[numberOfResources] memory _amount) public{
//	Regular checks and updates
	    require(registered[msg.sender] != 0, "Your address has not been registered.");
	    updateState();
	    uint8 selector = uint8((epoch + 1) % 2);
	    require(userList[registered[msg.sender]].demandEpoch[selector] < epoch, "You have already made a demand in this epoch.");

// 	Register demand
	saturated[selector] = 0;
	for(uint i = 0; i < numberOfResources; i++){
		userList[registered[msg.sender]].demanded[selector][i] = _amount[i];
	}

//	Find and register the dominant share
	uint[2] temp;
	for(uint i = 0; i < numberOfResources; i++){
		if(tem[0] < abs2percent(userList[registered[msg.sender]].demanded[selector][i], i, selector)){
			temp[0] = abs2percent(userList[registered[msg.sender]].demanded[selector][i], i, selector);
			temp[1] = i;
		}
	}
	
	userList[registered[msg.sender]].dominantShare[selector][0] = temp[0];
	userList[registered[msg.sender]].dominantShare[selector][1] = temp[1];

//	Update user demand epoch
	userList[registered[msg.sender]].demandEpoch[selector] = epoch;
	
//	Systemwide updates
	if(resetEpoch < epoch){
		numberOfDemands[selector] = 1;
		cumDominantShare[selector] = temp[0];
		maxDominantShare = temp[0];
		resetEpoch = epoch;
	    }            
	
	else{
		numberOfDemands[selector]++;
		cumDominantShare[selector] += temp[0];
		if(maxDominantShare[selector] < temp[0])
			maxDominantShare = temp[0];
	}
   }


   function claim() public{
//	Regular checks and updates
	updateState();
	uint8 selector = uint8(epoch % 2);
	if(userList[registered[msg.sender]].demandEpoch[selector] != epoch - 1) return;  //user did not make a demand in the previous epoch
	if(userList[registered[msg.sender]].claimEpoch != epoch)
	        userList[registered[msg.sender]].claimEpoch = epoch;
	else if(userList[registered[msg.sender]].claimRound == round || userList[registered[msg.sender]].dominantShare[selector][0] == 0) return;
	userList[registered[msg.sender]].claimRound = round;

// 	Check whether resources for the demand is saturated
	for(uint i = 0; i < numberOfResources; i++){
		if(userList[registered[msg.sender]].demanded[selector][i] < capacity[selector][i]){
			userList[registered[msg.sender]].saturated[selector] = 1;
			numberOfDemands[selector] --;
			cumDominantShare[selector] -= temp[0];
			return;
		}
	}

// 	Calculate and assign the (partial) share
	uint ratio = maxDominantShare[selector] / userList[registered[msg.sender]].dominantShare[selector][0];
	uint share;

	for(uint i = 0; i < numberOfResources; i++){
		share = unitShare * ratio * userList[registered[msg.sender]].demanded[selector][i];
		userList[registered[msg.sender]].balance[selector][i] += share;
		capacity[selector][i] -= share;
	}
   }


   function abs2percent(uint value, uint resourceType, uint selector) view private returns(uint) {
	return (value * precision) * 100 / capacity[selector][resourceType];
   }


   function percent2abs(uint value, uint resourceType, uint selector) view private returns(uint) {
	return (value * capacity[selector][resourceType]) / (precision * 100);
   } 


   function viewBalance(uint _user) view public returns(uint[numberOfResources] memory) {
	   		return userList[_user].balance;
   } 


   function viewDemand(uint _user) view public returns(uint[numberOfResources] memory) {
		uint selector = (epoch + 1) % 2;
		return userList[_user].demanded[selector];
   }


}
