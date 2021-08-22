// Share is calculated at state update, reset operation is done with reset array, no surplus


pragma solidity ^0.5.13;


contract Faucet{
    

    uint16 constant public quanta = 250;

    uint public offset;
    uint public epoch = 1;
    uint[quanta + 1][2] public resetEpoch;
    uint[2] demandsTotal;
    uint public capacity;
    uint public share;


    struct User{
        address payable userAddress;
        uint userId;
        uint16[2] demanded;
        uint demandEpoch;
        uint claimEpoch;
        uint balance;
        uint refund;
    }   
    
    mapping(address => uint) public registered;
    mapping(uint => User) public userList;
    uint[quanta + 1][2] public demands;

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
        uint epochCapacity = quanta * epochSpan / 4;
        if(epoch < (block.number - offset) / epochSpan + 1){
            epoch = (block.number - offset) / epochSpan + 1;
            capacity += epochCapacity;
            share = calculateShare();
            demandsTotal[(epoch + 1) % 2] = 0;
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
    
    function demand(uint16 _amount) public{
        require(registered[msg.sender] != 0, "Your address has not been registered.");
        require(_amount <= quanta, "Demand quantity is out of bounds");
        updateState();
        require(userList[registered[msg.sender]].demandEpoch < epoch, "You have made a demand in this epoch");
        uint8 selector = uint8((epoch + 1) % 2);

        if(resetEpoch[selector][_amount] < epoch){
            demands[selector][_amount] = 1;
            resetEpoch[selector][_amount] = epoch;
        }
        
        else{
            demands[selector][_amount]++;
        }
        
        userList[registered[msg.sender]].demanded[selector] = _amount;
        userList[registered[msg.sender]].demandEpoch = epoch;
        demandsTotal[selector] ++;
    }

    function calculateShare() public view returns(uint16){
        uint8 selector = uint8(epoch % 2);
        uint numberOfDemandsCumulative;
        uint demandVolumeCumulative;
        uint numberOfDemandsTotal = demandsTotal[selector];
        uint demand_i;
        uint16 i;
        

        for(i = 1; i <= quanta; i++){
            if(resetEpoch[selector][i] == epoch - 1){
                demand_i = demands[selector][i];
                numberOfDemandsCumulative += demand_i;
                demandVolumeCumulative += i * demand_i;
            }
            
            if(capacity < demandVolumeCumulative + i * (numberOfDemandsTotal - numberOfDemandsCumulative)) return i - 1;
        }
        
        return quanta;

    }
    
    function claim() public{
        updateState();
        require(userList[registered[msg.sender]].demandEpoch == epoch - 1, "You have not made demands in the previous epoch.");
        require(userList[registered[msg.sender]].claimEpoch < epoch, "You have claimed your share for the current epoch.");
        uint userShare = min(share, userList[registered[msg.sender]].demanded[epoch %2]);
        userList[registered[msg.sender]].claimEpoch = epoch;
        userList[registered[msg.sender]].balance += userShare;
        capacity -= userShare;

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
