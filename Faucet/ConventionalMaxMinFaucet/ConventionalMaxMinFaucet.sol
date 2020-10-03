//Distributes the 'capacity' capacity among the demanders according to the Max-Min Fairness algorithm


pragma solidity ^0.5.13;

import "../heap/heap_v_2.0.sol";

contract Faucet is Heaped{
    struct User{
        address payable userAddress;
        uint userId;
        uint demanded;
        uint totalReceived;
        uint totalDemanded;
        uint balance;
    }
    
    mapping(address => uint) public registered;
    mapping(uint => User) public userList;
    
    address owner;
    uint public capacity;
    uint public epochCapacity;
    uint public numberOfUsers;
    uint public units;

    constructor() public{
        owner = msg.sender;
        units = 1 szabo;
        epochCapacity = 50 * units;
    }
    
    function depositMoney() public payable{
        require(msg.sender == owner, "Only the owner can deposit money to the contract.");
    }
    
    function withdrawMoney(address payable _to, uint _amount) public{
        require(_amount*units <= userList[registered[msg.sender]].balance, "You do not have enough funds.");
        userList[registered[msg.sender]].balance -= _amount*units;
        _to.transfer(_amount);
    }
    
    function registerUser(address payable _user) public{
        require (msg.sender == owner, "You have to be the owner of the contract in order to call that function.");
        require (registered[_user] == 0, "The user has already been registered.");
        numberOfUsers++;
        registered[_user] = numberOfUsers;
        userList[registered[_user]].userAddress = _user;
        userList[registered[_user]].userId = numberOfUsers;
    }
    
    function demand(uint _amount) public{
        require(registered[msg.sender] != 0, "Your address has not been registered.");
//        require(userList[registered[msg.sender]].demanded == 0, "You have already made a demand for that round.");
        userList[registered[msg.sender]].demanded = _amount*units;
        userList[registered[msg.sender]].totalDemanded += _amount*units;
        push(0, _amount*units, registered[msg.sender]);
    }
    
    function distribute() public {
//        require(msg.sender == owner, "You have to be the owner of the contract in order to call that function.");
        capacity += epochCapacity;                                       //renew capacity
        uint numberOfDemands = demandHeap[0].length;                    //get number of demands
        uint share;
        uint8 selector = 0;

        while(demandHeap[selector].length != 0){
            
            share = capacity / numberOfDemands;
            
            while(demandHeap[selector].length != 0 && demandHeap[selector][0].demanded <= share){
                userList[demandHeap[selector][0].id].totalReceived += userList[demandHeap[selector][0].id].demanded;
                userList[demandHeap[selector][0].id].balance += userList[demandHeap[selector][0].id].demanded;
                userList[demandHeap[selector][0].id].demanded = 0;
                capacity -= demandHeap[selector][0].demanded;
                pop(selector);
            }

            while(demandHeap[selector].length != 0){
                userList[demandHeap[selector][0].id].totalReceived += share;
                userList[demandHeap[selector][0].id].balance += share;
                userList[demandHeap[selector][0].id].demanded -= share;
                capacity -= share;
                push(1 - selector, userList[demandHeap[selector][0].id].demanded, demandHeap[selector][0].id);
                pop(selector);
            }
	        if(capacity == 0){
	            emptyHeap(1 - selector);
        		return;
	        }
        	selector = 1 - selector;
        	numberOfDemands = demandHeap[selector].length;
        }
    }
}
