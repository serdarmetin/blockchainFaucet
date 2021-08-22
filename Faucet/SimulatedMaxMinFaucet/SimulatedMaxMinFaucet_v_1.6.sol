pragma solidity ^0.5.13;

import "HeapOperationsUint.sol";

contract Faucet is Heaped{
    

    uint public offset;
    uint public epoch = 1;
    uint public capacity;
    uint public share;


    struct User{
        address payable userAddress;
        uint userId;
        uint[2] demanded;
        uint[2] demandEpoch;
        uint claimEpoch;
        uint balance;
        uint refund;
    }   
    
    mapping(address => uint) public registered;
    mapping(uint => User) public userList;

    address owner;
    uint public numberOfUsers;

    constructor() public{
        owner = msg.sender;
        offset = block.number + 1;
    }   
    
    function updateState() public {
        //Update epoch: epoch starts from 1 to prevent triggering "already demanded" in the first epoch
        uint startGas = gasleft();
        uint epochCapacity = 5000;
        uint epochSpan = 500;
        if(epoch < (block.number - offset) / epochSpan + 1){
            epoch = (block.number - offset) / epochSpan + 1;
            capacity += epochCapacity;
            share = calculateShare();
        }
        userList[registered[msg.sender]].refund = (1 + tx.gasprice) * (startGas - gasleft());
    }

    function depositMoney() public payable{
        require(msg.sender == owner, "Only the owner can deposit money to the contract.");
    }   
    
    function withdrawMoney(address payable _to, uint _amount) public{
        uint units = 1;
        require(_amount*units <= userList[registered[msg.sender]].balance, "You do not have enough funds.");
        userList[registered[msg.sender]].balance -= _amount*units;
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
    
    function demand(uint _amount) public{
        require(registered[msg.sender] != 0, "Your address has not been registered.");
        updateState();
        uint8 selector = uint8((epoch + 1) % 2);
        require(userList[registered[msg.sender]].demandEpoch[selector] < epoch, "You have made a demand in this epoch");

        userList[registered[msg.sender]].demanded[selector] = _amount;
        userList[registered[msg.sender]].demandEpoch[selector] = epoch;
    }

    function calculateShare() public view returns(uint){
        uint8 selector = uint8(epoch % 2);
        uint[] memory heap = new uint[](numberOfUsers);
        uint length;
        uint simulatedCapacity = capacity;
        uint simulatedShare;
        uint result;
        uint i;


        for(i = 1; i <= numberOfUsers; i++){
            if(userList[i].demandEpoch[selector] == epoch - 1 && userList[i].claimEpoch < epoch){
                push(heap, length, userList[i].demanded[selector]);
                length++;
            }
        }
        
        simulatedShare = simulatedCapacity / length;
                

        while(length > 0 && simulatedCapacity >= length){
            
            while(heap[0] < simulatedShare){
                simulatedCapacity -= heap[0];
                pop(heap, length);
                length--;
            }
            
            simulatedCapacity -= simulatedShare * length;

            for(i = 0; i < length; i++)
                heap[i] -= simulatedShare;

            result += simulatedShare;
            simulatedShare = simulatedCapacity / length;
        }
        
        return result;
    }
    
    function claim() public{
        updateState();
        uint8 selector = uint8(epoch % 2);
        require(userList[registered[msg.sender]].demandEpoch[selector] == epoch - 1, "You have not made demands in the previous epoch.");
        require(userList[registered[msg.sender]].claimEpoch < epoch, "You have claimed your share for the current epoch.");
        uint userShare = min(share, userList[registered[msg.sender]].demanded[selector]);

        capacity -= userShare;
        userList[registered[msg.sender]].balance += userShare;
        userList[registered[msg.sender]].claimEpoch = epoch;

    }
    
    function min(uint a, uint b) private pure returns (uint) {
    	if(a < b) return a; return b;
    }
    
    function viewBalance(uint _user) public view returns(uint){
        return userList[_user].balance;
    }

    function viewRefund(uint _user) public view returns(uint){
       return userList[_user].refund;
    }
}
