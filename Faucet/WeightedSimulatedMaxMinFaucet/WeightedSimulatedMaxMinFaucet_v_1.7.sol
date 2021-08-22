//  Utilizes demand volume based min-heap, constant weight

pragma solidity ^0.5.13;
pragma experimental ABIEncoderV2;

import "MinHeapOperationsNode.sol";

contract Faucet is Heaped{

    uint constant units = 1;
    uint constant epochSpan = 20;
    uint constant epochCapacity = 10 * epochSpan * units;

    uint public offset;
    uint public epoch = 1;
    uint public capacity;
    uint public unitShare;


    struct User{
        uint[2] demanded;
        uint demandEpoch;
        uint claimEpoch;
        uint weight;
        uint balance;
        uint refund;
    }   
    
    mapping(address => uint) public registered;
    mapping(address => User) public userList;

    address owner;
    node[500][2] demands;
    uint[2] totalWeight;
    uint[2] numberOfDemands;
    uint public numberOfUsers;

    constructor() public{
        owner = msg.sender;
        offset = block.number + 1;
    }   
    
    function depositMoney() public payable{
        require(msg.sender == owner, "Only the owner can deposit money to the contract.");
    }   
    
    function withdrawMoney(address payable _to, uint _volume) public{
        require(_volume*units <= userList[msg.sender].balance, "You do not have enough funds.");
        userList[msg.sender].balance -= _volume*units;
        _to.transfer(_volume);
    }   
    
    function registerUser(address payable _user, uint _weight) public{
        require (msg.sender == owner, "You have to be the owner of the contract in order to call this function.");
        require (registered[_user] == 0, "The user has already been registered.");
        registered[_user] = 1;
        userList[msg.sender].weight = _weight;
    }
    
    function updateState() public {
        //Update epoch: epoch starts from 1 to prevent triggering "already demanded" in the first epoch
        uint startGas = gasleft();
        if(epoch < (block.number - offset) / epochSpan + 1){
            epoch = (block.number - offset) / epochSpan + 1;
            capacity += epochCapacity;
            unitShare = calculateUnitShare();
            totalWeight[(epoch + 1) % 2] = 0;
            numberOfDemands[(epoch + 1) % 2] = 0;
        }
        userList[msg.sender].refund = (1 + tx.gasprice) * (startGas - gasleft());
    }
    
    function demand(uint _volume) public{
        require(registered[msg.sender] != 0, "Your address has not been registered.");
        updateState();
        uint8 selector = uint8((epoch + 1) % 2);
        require(userList[msg.sender].demandEpoch < epoch, "You have made a demand in this epoch");

        userList[msg.sender].demanded[selector] = _volume;
        userList[msg.sender].demandEpoch = epoch;
        
        demands[selector][numberOfDemands[selector]] = node(_volume, userList[msg.sender].weight);
        totalWeight[selector] += userList[msg.sender].weight;
    	numberOfDemands[selector]++;
    }

    function calculateUnitShare() public view returns(uint){
        uint8 selector = uint8(epoch % 2);
        node[][2] memory heap;
        uint[2] memory length;
        uint result;
        uint simulatedTotalWeight = totalWeight[selector];
        uint simulatedCapacity = capacity;
        uint simulatedUnitShare;
        uint simulatedShare;
        uint i;
        

        heap[0] = new node[](numberOfDemands[selector]);
        heap[1] = new node[](numberOfDemands[selector]);
        
        for(i = 0; i < numberOfDemands[selector]; i++){
                push(heap[0], length[0], demands[selector][i]);
                length[0]++;
        }
        
        selector = 0;

        while(length[selector] > 0 && simulatedCapacity >= simulatedTotalWeight){    

            simulatedUnitShare = simulatedCapacity / simulatedTotalWeight;
            result += simulatedUnitShare;

            while(length[selector] > 0){
                
                simulatedShare = heap[selector][0].weight * simulatedUnitShare;
               
                if(heap[selector][0].volume <= simulatedShare){
                    simulatedCapacity -= heap[selector][0].volume;
                    simulatedTotalWeight -= heap[selector][0].weight;
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
        require(userList[msg.sender].demandEpoch == epoch - 1, "You have not made demands in the previous epoch.");
        require(userList[msg.sender].claimEpoch < epoch, "You have claimed your unitShare for the current epoch.");
        uint share = min(userList[msg.sender].weight * unitShare, userList[msg.sender].demanded[epoch % 2]);
        
        capacity -= share;
        userList[msg.sender].balance += share;
        userList[msg.sender].claimEpoch = epoch;
    }
    
    function min(uint a, uint b) private pure returns (uint) {
    	if(a < b) return a; return b;
    }
    
    function viewBalance() public view returns(uint){
        return userList[msg.sender].balance;
    }    

    function viewWeight() public view returns(uint){
        return userList[msg.sender].weight;
    }

    function viewRefund() public view returns(uint){
       return userList[msg.sender].refund;
    }
}
