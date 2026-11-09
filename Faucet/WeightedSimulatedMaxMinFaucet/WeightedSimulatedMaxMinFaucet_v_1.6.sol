//  Utilizes demand volume based min-heap, constant weight

pragma solidity ^0.5.13;
pragma experimental ABIEncoderV2;

import "MinHeapOperationsNode.sol";

contract Faucet is Heaped{

    uint constant units = 1;
    uint constant epochSpan = 500;
    uint constant epochCapacity = 10 * epochSpan * units;

    uint public offset;
    uint public epoch = 1;
    uint public capacity;
    uint public unitShare;


    struct User{
        address payable userAddress;
        uint userId;
        uint[2] demanded;
        uint demandEpoch;
        uint claimEpoch;
        uint weight;
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
    
    function depositMoney() public payable{
        require(msg.sender == owner, "Only the owner can deposit money to the contract.");
    }   
    
    function withdrawMoney(address payable _to, uint _volume) public{
        require(_volume*units <= userList[registered[msg.sender]].balance, "You do not have enough funds.");
        userList[registered[msg.sender]].balance -= _volume*units;
        _to.transfer(_volume);
    }   
    
    function registerUser(address payable _user, uint _weight) public{
        require (msg.sender == owner, "You have to be the owner of the contract in order to call this function.");
        require (registered[_user] == 0, "The user has already been registered.");
        numberOfUsers++;
        registered[_user] = numberOfUsers;
        userList[registered[_user]].userAddress = _user;
        userList[registered[_user]].userId = numberOfUsers;
        userList[registered[_user]].weight = _weight;
    }
    
    function updateState() public {
        //Update epoch: epoch starts from 1 to prevent triggering "already demanded" in the first epoch
        uint startGas = gasleft();
        if(epoch < (block.number - offset) / epochSpan + 1){
            epoch = (block.number - offset) / epochSpan + 1;
            capacity += epochCapacity;
            unitShare = calculateUnitShare();
        }
        userList[registered[msg.sender]].refund = (1 + tx.gasprice) * (startGas - gasleft());
    }
    
    function demand(uint _volume) public{
        require(registered[msg.sender] != 0, "Your address has not been registered.");
        updateState();
        uint8 selector = uint8((epoch + 1) % 2);
        require(userList[registered[msg.sender]].demandEpoch < epoch, "You have made a demand in this epoch");

        userList[registered[msg.sender]].demanded[selector] = _volume;
        userList[registered[msg.sender]].demandEpoch = epoch;
    }

    function calculateUnitShare() public view returns(uint){
        uint8 selector = uint8(epoch % 2);
        node[][2] memory heap;
        uint[2] memory length;
        uint totalWeight;
        uint result;
        uint simulatedCapacity = capacity;
        uint simulatedUnitShare;
        uint simulatedShare;
        uint i;
        

        heap[0] = new node[](numberOfUsers);
        heap[1] = new node[](numberOfUsers);
        
        for(i = 1; i <= numberOfUsers; i++){
            if(userList[i].demandEpoch == epoch - 1 && userList[i].claimEpoch < epoch){
                push(heap[0], length[0], node(userList[i].demanded[selector], userList[i].weight));
                length[0]++;
                totalWeight += userList[i].weight;
            }
        }
        
        selector = 0;

        while(length[selector] > 0 && simulatedCapacity > totalWeight){    

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
        require(userList[registered[msg.sender]].demandEpoch == epoch - 1, "You have not made demands in the previous epoch.");
        require(userList[registered[msg.sender]].claimEpoch < epoch, "You have claimed your unitShare for the current epoch.");
        uint share = min(userList[registered[msg.sender]].weight * unitShare, userList[registered[msg.sender]].demanded[epoch % 2]);
        
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

    function viewWeight(uint _user) public view returns(uint){
        return userList[_user].weight;
    }

    function viewRefund(uint _user) public view returns(uint){
       return userList[_user].refund;
    }
}
