pragma solidity ^0.5.13;


contract Faucet{
    
    uint16 constant public quanta = 250;

    uint public offset;
    uint public epoch = 1;
    uint[quanta + 1][2] public indexReset;
    uint[2] totalWeights;
    uint public capacity;
    uint public unitShare;


    struct User{
        address payable userAddress;
        uint userId;
        uint16[2] demanded;
        uint demandEpoch;
        uint claimEpoch;
        uint weight;
        uint balance;
        uint refund;
    }   
    
    mapping(address => uint) public registered;
    mapping(uint => User) public userList;
    uint[quanta + 1][2] public demands;
    uint[quanta + 1][2] public weights;

    address owner;
    uint public numberOfUsers;

    constructor() public{
        owner = msg.sender;
        offset = block.number + 1;
    }   
    
    function updateState() public {
        //Update epoch: epoch starts from 1 to prevent triggering "already demanded" in the first epoch
        uint startGas = gasleft();
        uint epochSpan = 2000;
        uint epochCapacity = epochSpan * (quanta) / 4;
        if(epoch < (block.number - offset) / epochSpan + 1){
            epoch = (block.number - offset) / epochSpan + 1;
            capacity += epochCapacity;
            unitShare = calculateUnitShare();
            totalWeights[(epoch + 1) % 2] = 0;
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
    
    function registerUser(address payable _user, uint _weight) public{
        require (msg.sender == owner, "You have to be the owner of the contract in order to call this function.");
        require (registered[_user] == 0, "The user has already been registered.");
        numberOfUsers++;
        registered[_user] = numberOfUsers;
        userList[registered[_user]].userAddress = _user;
        userList[registered[_user]].userId = numberOfUsers;
        userList[registered[_user]].weight = _weight;
    }
    
    function demand(uint16 _amount) public{
        require(registered[msg.sender] != 0, "Your address has not been registered.");
        require(_amount <= quanta, "Demand quantity is out of bounds");
        updateState();
        require(userList[registered[msg.sender]].demandEpoch < epoch, "You have made a demand in this epoch");
        uint8 selector = uint8((epoch + 1) % 2);
        uint index;

        index = _amount / userList[registered[msg.sender]].weight;
	if(_amount % userList[registered[msg.sender]].weight != 0) index++;

        if(indexReset[selector][index] < epoch){
            demands[selector][index] = _amount;
            weights[selector][index] = userList[registered[msg.sender]].weight;
            indexReset[selector][index] = epoch;
        }
        
        else{
            demands[selector][index]+= _amount;
            weights[selector][index]+= userList[registered[msg.sender]].weight;
        }
                    
        userList[registered[msg.sender]].demanded[selector] = _amount;
        userList[registered[msg.sender]].demandEpoch = epoch;
        totalWeights[selector] += userList[registered[msg.sender]].weight;
    }


    function calculateUnitShare() public view returns(uint16){
        uint8 selector = uint8(epoch % 2);
        uint cumulativeDemands;
        uint cumulativeWeights;
        uint16 i;
       
        for(i = 1; i <= quanta; i++){
            if(indexReset[selector][i] == epoch - 1){
                cumulativeDemands += demands[selector][i];
                cumulativeWeights += weights[selector][i];
            }

            if(capacity < cumulativeDemands + i * (totalWeights[selector] - cumulativeWeights)) return i - 1;
 
        }
        
        return quanta;

    }
    
    function claim() public{
        updateState();
        require(userList[registered[msg.sender]].demandEpoch == epoch - 1, "You have not made demands in the previous epoch.");
        require(userList[registered[msg.sender]].claimEpoch < epoch, "You have claimed your share for the current epoch.");
        uint8 selector = uint8(epoch % 2);
        uint share = min(unitShare * userList[registered[msg.sender]].weight, userList[registered[msg.sender]].demanded[selector]);

        userList[registered[msg.sender]].claimEpoch = epoch;
        userList[registered[msg.sender]].balance += share;
        capacity -= share;

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
