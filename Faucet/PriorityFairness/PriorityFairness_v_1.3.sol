pragma solidity ^0.5.13;
pragma experimental ABIEncoderV2;

import "./MinHeapOperationsNode.sol";

contract Faucet is Heaped{

    //State variables
    uint constant numberOfResources = 4;
    uint units = 1;
    uint roundSpan = 10;
    uint epochSpan = roundSpan * 4;
    uint[numberOfResources] epochCapacity;

    address owner;
    uint public offset;
    uint[numberOfResources] public capacity;
    uint[numberOfResources] public share;
    uint[2][numberOfResources] public numberOfDemands;
    uint public numberOfUsers;
    uint public epoch = 1;
    uint public round;
    uint public resetEpoch;
    

    struct User{
        address payable userAddress;
        uint userId;
        uint claimEpoch;
        uint claimRound;
        uint[2] demandEpoch;
        uint[numberOfResources] balance;
        uint[2][numberOfResources] demanded;
	uint[2][numberOfResources] typeOrder;
    }

    mapping(address => uint) public registered;
    mapping(uint => User) public userList;

    constructor() public{
        owner = msg.sender;
        offset = block.number + 1;
	for(uint i = 0; i < numberOfResources; i++){
		epochCapacity[i] = roundSpan * 20 * units;
    }
    }

    function depositMoney() public payable{
        require(msg.sender == owner, "Only the owner can deposit money to the contract.");
    }

    function withdrawMoney(address payable _to, uint _amount, uint _resourceType) public{
        require(_amount*units <= userList[registered[msg.sender]].balance[_resourceType], "You do not have enough funds.");
        userList[registered[msg.sender]].balance[_resourceType] -= _amount * units;
        _to.transfer(_amount);
    }

    function registerUser(address payable _user) public{
        require (msg.sender == owner, "You have to be the owner of the contract in order to call this function.");
        require (registered[_user] == 0, "The user has already been registered.");
        numberOfUsers++;
        registered[_user] = numberOfUsers;
        userList[registered[_user]].userAddress = _user;
        userList[registered[_user]].userId = numberOfUsers;
    }


/*
	This is the function to update the global state of the system
	which is called at the beginning of "demand" and "claim" functions.
	It is responsible for the synchronisation of Epochs and Rounds,
	and replenishment of the resources according to the variable "epochCapacity"
*/

    function updateState() public {
        //Update epoch & round: epoch starts from 1 to prevent triggering "already demanded" in the first epoch
        if(epoch < (block.number - offset) / epochSpan + 1){
            epoch = (block.number - offset) / epochSpan + 1;
            round = ((block.number - offset) % epochSpan) / roundSpan + 1;
	    for(uint i = 0; i < numberOfResources; i++){
            	capacity[i] += epochCapacity[i];
            }
            uint8 selector = uint8(epoch % 2);


	    for(uint i = 0; i < numberOfResources; i++){
	            if(numberOfDemands[i][selector] != 0)
        	        share[i] = capacity[i] / numberOfDemands[i][selector];
		}
        }

        //Epoch is up-to-date, so uupdate only the round: round also starts from 1 to prevent triggering "already claimed" in the first round
        else if(round != ((block.number - offset) % epochSpan) / roundSpan + 1){
            round = ((block.number - offset) % epochSpan) / roundSpan + 1;

            uint8 selector = uint8(epoch % 2);
            
	    for(uint i = 0; i < numberOfResources; i++){
            	if(numberOfDemands[i][selector] > 0)
        	        share[i] = capacity[i] / numberOfDemands[i][selector];
		    }
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

//	Initiate a heap to sort the demands to determine the order of relative dominance of the resource types for the user

        resource[] memory heap = new resource[](numberOfResources);
	uint length;

	userList[registered[msg.sender]].demandEpoch[selector] = epoch;

	for(uint i = 0; i < numberOfResources; i++){
		push(heap, length, resource(_amount[i], i));
		length++;
	}

//	Insert the demands to their corresponding demand list 

	for(uint i = 0; i < numberOfResources; i++){
        	userList[registered[msg.sender]].demanded[i][selector] = heap[0].amount;
        	userList[registered[msg.sender]].typeOrder[i][selector] = heap[0].resourceType;	
		pop(heap, length);
		length--;

	        if(resetEpoch < epoch){
	            numberOfDemands[i][selector] = 1;
        	    resetEpoch = epoch;
            	}            

            	else numberOfDemands[i][selector]++;
	}
   }

/*
	User accessible function for users to claim their reserved shares
*/

   function claim() public{

//	Regular checks and updates
       updateState();
       uint8 selector = uint8(epoch % 2);
       if(userList[registered[msg.sender]].demandEpoch[selector] != epoch - 1) return;

       if(userList[registered[msg.sender]].claimEpoch == epoch){        //user has claimed her fair share in this epoch
           require(userList[registered[msg.sender]].claimRound < round, "You have already claimed your share for this round!");
           userList[registered[msg.sender]].claimRound = round;
        }

       else{                                                            //new epoch has started since the user's last claim, so update it to be the present epoch and round
           userList[registered[msg.sender]].claimEpoch = epoch;
           userList[registered[msg.sender]].claimRound = round;
        }


/*	Claim each resource in order of the demand queues, 
	and resolve its type to record the available fair
	share to its corresponding resource type in user's balance;
	and deduce it from the corresponding resource type
*/
	for(uint i = 0; i < numberOfResources; i++){
		if(userList[registered[msg.sender]].demanded[i][selector] <= share[i]){
        	   userList[registered[msg.sender]].balance[userList[registered[msg.sender]].typeOrder[i][selector]] += userList[registered[msg.sender]].demanded[i][selector];
	           capacity[userList[registered[msg.sender]].typeOrder[i][selector]] -= userList[registered[msg.sender]].demanded[i][selector];
        	   userList[registered[msg.sender]].demanded[i][selector] = 0;
	           numberOfDemands[i][selector]--;
		}

		else{
           		userList[registered[msg.sender]].balance[userList[registered[msg.sender]].typeOrder[i][selector]] += share[i];
		        userList[registered[msg.sender]].demanded[i][selector] -= share[i];
		        capacity[i] -= share[i];
        	}
	}
   }

   function viewBalance(uint _user) public view returns(uint[numberOfResources] memory){
       		return userList[_user].balance;
   }

   function viewDemand(uint _user) public view returns(uint[numberOfResources] memory){
		uint selector = (epoch + 1) % 2;
		uint[numberOfResources] memory result;
		for(uint i = 0; i < numberOfResources; i++){
			result[i] = userList[_user].demanded[i][selector];
		}
       		return result;
   }


}
