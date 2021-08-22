//  Utilizes demand volume based min-heap, weight defined to be reciprocal of total demand

pragma solidity ^0.5.13;
pragma experimental ABIEncoderV2;

import "MinHeapOperationsNode.sol";

contract Faucet is Heaped{


    uint constant epochSpan = 500;
    uint constant epochCapacity = epochSpan * 10;

   
    uint public offset;
    uint public epoch = 1;
    uint public capacity;
    uint public unitShare;

    struct User{
        address payable userAddress;
        uint userId;
        uint[2] demanded;
        uint[2] demandEpoch;
        uint claimEpoch;
        uint totalDemanded;
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
        if(epoch < (block.number - offset) / epochSpan + 1){
            epoch = (block.number - offset) / epochSpan + 1;
            capacity += epochCapacity;
            unitShare = calculateShare();
        }
        userList[registered[msg.sender]].refund = (1 + tx.gasprice) * (startGas - gasleft());
    }

    function depositMoney() public payable{
        require(msg.sender == owner, "Only the owner can deposit money to the contract.");
    }   
    
    function withdrawMoney(address payable _to, uint _volume) public{
        require(_volume <= userList[registered[msg.sender]].balance, "You do not have enough funds.");
        userList[registered[msg.sender]].balance -= _volume;
        _to.transfer(_volume);
    }   
    
    function registerUser(address payable _user) public{
        require (msg.sender == owner, "You have to be the owner of the contract in order to call this function.");
        require (registered[_user] == 0, "The user has already been registered.");
        numberOfUsers++;
        registered[_user] = numberOfUsers;
        userList[registered[_user]].userAddress = _user;
        userList[registered[_user]].userId = numberOfUsers;
    }
    
    function demand(uint _volume) public{
        require(registered[msg.sender] != 0, "Your address has not been registered.");
        updateState();
        uint8 selector = uint8((epoch + 1) % 2);
        require(userList[registered[msg.sender]].demandEpoch[selector] < epoch, "You have made a demand in this epoch");

        userList[registered[msg.sender]].demanded[selector] = _volume;
        userList[registered[msg.sender]].demandEpoch[selector] = epoch;
        userList[registered[msg.sender]].totalDemanded += _volume;
    }

    function calculateShare() public view returns(uint){
        node[][2] memory heap;
        uint[2] memory length;
        uint userWeight;
        uint totalWeight;
        uint precision = 1 szabo;
        uint simulatedCapacity = capacity * precision;
        uint simulatedUnitShare;
        uint simulatedShare;
        uint result;
        uint8 selector = uint8(epoch % 2);
        uint16 i;


        heap[0] = new node[](numberOfUsers);
        heap[1] = new node[](numberOfUsers);
        
        for(i = 1; i <= numberOfUsers; i++){
            if(userList[i].demandEpoch[selector] == epoch - 1){
                userWeight = precision / userList[i].totalDemanded;
                push(heap[0], length[0], node(userList[i].demanded[selector] * precision, userWeight));
                length[0]++;
                totalWeight += userWeight;
            }
        }
        
        selector = 0;

	while(length[selector] > 0 && simulatedCapacity >= totalWeight){

            simulatedUnitShare = simulatedCapacity / totalWeight;
            result += simulatedUnitShare;           

            while(length[selector] > 0){
                
                simulatedShare = heap[selector][0].weight * simulatedUnitShare;

               if(heap[selector][0].volume <= simulatedShare){
                    simulatedCapacity -= heap[selector][0].volume;
                    totalWeight -= heap[selector][0].weight;
                    pop(heap[selector], length[selector]);
                    length[selector]--;
                }
                
                else{
                    simulatedCapacity -= simulatedShare;
                    heap[selector][0].volume -= simulatedShare;
                    push(heap[1 - selector], length[1 - selector], heap[selector][0]);
                    length[1 - selector]++;
                    pop(heap[selector], length[selector]);
                    length[selector]--;
                }
            }    

           selector = 1 - selector;
            
         }

        return result;
    }
    
    function claim() public{
        updateState();
        uint8 selector = uint8(epoch % 2);
        require(userList[registered[msg.sender]].demandEpoch[selector] == epoch - 1, "You have not made demands in the previous epoch.");
        require(userList[registered[msg.sender]].claimEpoch < epoch, "You have claimed your share for the current epoch.");
        uint share;

        
        if(userList[registered[msg.sender]].demandEpoch[1 - selector] == epoch)
            share = min(unitShare / (userList[registered[msg.sender]].totalDemanded - 
                        userList[registered[msg.sender]].demanded[1 - selector]), userList[registered[msg.sender]].demanded[selector]);
        else
            share = min(unitShare / userList[registered[msg.sender]].totalDemanded, userList[registered[msg.sender]].demanded[selector]);


        capacity -= share;
        userList[registered[msg.sender]].balance += share;
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
