// DRF employing AMF


pragma solidity ^0.5.13;
pragma experimental ABIEncoderV2;


contract Faucet{

    //State variables
    uint constant numberOfResources = 4;
    uint roundSpan = 10;
    uint epochSpan = roundSpan * 4;
    uint[numberOfResources] epochCapacity;
    uint[numberOfResources] leftoverCapacity;
    uint[numberOfResources] capacity;
    uint percentCapacity;
    uint precision = 1000000;

    address owner;
    uint offset;
    uint share;
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
	uint[2][2] dominantShare; // 0 for amount 1 for type
    }

    mapping(address => uint) registered;
    mapping(uint => User) userList;


    constructor() public {
        owner = msg.sender;
        offset = block.number + 1;
	for(uint i = 0; i < numberOfResources; i++){
		epochCapacity[i] = 200;
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
            	capacity[i] = epochCapacity[i] + leftoverCapacity[i];
		leftoverCapacity[i] = capacity[i];
            }

            uint8 selector = uint8(epoch % 2);
	    percentCapacity = 100 * precision;
	    share = percentCapacity  / numberOfDemands[selector];

        }

        //Epoch is up-to-date, so update only the round: round also starts from 1 to prevent triggering "already claimed" in the first round
        else if(round != ((block.number - offset) % epochSpan) / roundSpan + 1){
            round = ((block.number - offset) % epochSpan) / roundSpan + 1;

            uint8 selector = uint8(epoch % 2);
	    if(numberOfDemands[selector] == 0) return;
	    else
	        share = percentCapacity / numberOfDemands[selector];
        }
    }

/*
	User accessible functions for users to submit their demands
*/

 function demand(uint[numberOfResources] memory _amount) public{
//	Regular checks and updates
        require(registered[msg.sender] != 0, "Your address has not been registered.");
        updateState();
        uint8 selector = uint8((epoch + 1) % 2);
        require(userList[registered[msg.sender]].demandEpoch[selector] < epoch, "You have already made a demand in this epoch.");

	for(uint i = 0; i < numberOfResources; i++){
		userList[registered[msg.sender]].demanded[selector][i] = _amount[i];
	}

        if(resetEpoch < epoch){
            numberOfDemands[selector] = 1;
            resetEpoch = epoch;
        }            

            	else numberOfDemands[selector]++;

	userList[registered[msg.sender]].demandEpoch[selector] = epoch;
   }

/*
	User accessible function for users to claim their reserved shares
*/

function claim() public{
//	Regular checks and updates
	updateState();
	if(percentCapacity == 0) return;							//resources for the present epoch is depleted
	uint8 selector = uint8(epoch % 2);
	if(userList[registered[msg.sender]].demandEpoch[selector] != epoch - 1) return;  //user did not make a demand in the previous epoch


	if(userList[registered[msg.sender]].claimEpoch != epoch){
	        userList[registered[msg.sender]].claimEpoch = epoch;
//		Find the dominant share
		userList[registered[msg.sender]].dominantShare[selector][0] = 0;

		for(uint i = 0; i < numberOfResources; i++){
			if(userList[registered[msg.sender]].dominantShare[selector][0] < abs2percent(userList[registered[msg.sender]].demanded[selector][i], i)){
				userList[registered[msg.sender]].dominantShare[selector][0] = abs2percent(userList[registered[msg.sender]].demanded[selector][i], i);
				userList[registered[msg.sender]].dominantShare[selector][1] = i;
			}
		}
	}

	else if(userList[registered[msg.sender]].claimRound == round || userList[registered[msg.sender]].dominantShare[selector][0] == 0) return;

	userList[registered[msg.sender]].claimRound = round;

//	Calculate and assign received (partial) share
	if(userList[registered[msg.sender]].dominantShare[selector][0] <= share){
	        numberOfDemands[selector]--;

		percentCapacity -= userList[registered[msg.sender]].dominantShare[selector][0];

		for(uint i = 0; i < numberOfResources; i++){
        	   userList[registered[msg.sender]].balance[i] += userList[registered[msg.sender]].demanded[selector][i];
	           leftoverCapacity[i] -= userList[registered[msg.sender]].demanded[selector][i];
		}
		userList[registered[msg.sender]].dominantShare[selector][0] = 0;
	}

	else{
		uint typeShare;
		for(uint i = 0; i < numberOfResources; i++){
			typeShare = abs2percent(userList[registered[msg.sender]].demanded[selector][i], i) * share / userList[registered[msg.sender]].dominantShare[selector][0];
			userList[registered[msg.sender]].balance[i] += percent2abs(typeShare, i);
			userList[registered[msg.sender]].demanded[selector][i] -= percent2abs(typeShare, i);
			leftoverCapacity[i] -= percent2abs(typeShare, i);
		}

		userList[registered[msg.sender]].dominantShare[selector][0] -= share;
		percentCapacity -= share;
       	}

}

function abs2percent(uint value, uint resourceType) view private returns(uint){
	return (value * precision) * 100 / capacity[resourceType];
   }

function percent2abs(uint value, uint resourceType) view private returns(uint) {
	return (value * capacity[resourceType]) / (precision * 100);
   } 

function viewBalance(uint _user) view public returns(uint[numberOfResources] memory) {
       		return userList[_user].balance;
   } 

function viewDemand(uint _user) view public returns(uint[numberOfResources] memory) {
		uint selector = (epoch + 1) % 2;
		return userList[_user].demanded[selector];
   }


}
