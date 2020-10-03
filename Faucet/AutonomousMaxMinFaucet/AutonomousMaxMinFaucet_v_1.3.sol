pragma solidity ^0.5.13;


contract Faucet{

    //State variables
    uint units = 1;
    uint epochCapacity = 10000 * units;
    uint epochSpan = 2000;
    uint roundSpan = 500;

    address owner;
    uint public offset;
    uint public capacity;
    uint public numberOfUsers;
    uint public share;
    uint public epoch;
    uint public round;
    uint[2] public numberOfDemands;
    uint public resetEpoch;
    

    struct User{
        address payable userAddress;
        uint userId;
        uint[2] demanded;
        uint balance;
        uint[2] demandEpoch;
        uint claimEpoch;
        uint claimRound;
    }

    mapping(address => uint) public registered;
    mapping(uint => User) public userList;

    constructor() public{
        owner = msg.sender;
        offset = block.number + 1;
        epoch = 1;          //epoch starts from 1 to prevent triggering "already demanded" in the first epoch
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
        require (msg.sender == owner, "You have to be the owner of the contract in order to call this function.");
        require (registered[_user] == 0, "The user has already been registered.");
        numberOfUsers++;
        registered[_user] = numberOfUsers;
        userList[registered[_user]].userAddress = _user;
        userList[registered[_user]].userId = numberOfUsers;
    }

    function updateState() public {
        //Update epoch & round: epoch starts from 1 to prevent triggering "already demanded" in the first epoch
        if(epoch < (block.number - offset) / epochSpan + 1){
            epoch = (block.number - offset) / epochSpan + 1;
            round = ((block.number - offset) % epochSpan) / roundSpan + 1;
            capacity += epochCapacity;
            
            uint8 selector = uint8(epoch % 2);

            if(numberOfDemands[selector] != 0)
                share = capacity / numberOfDemands[selector];
        }

        //Update only round: round starts from 1 to prevent triggering "already claimed" in the first round
        else if(round != ((block.number - offset) % epochSpan) / roundSpan + 1){
            round = ((block.number - offset) % epochSpan) / roundSpan + 1;

            uint8 selector = uint8(epoch % 2);
            
            if(numberOfDemands[selector] != 0)
                share = capacity / numberOfDemands[selector];
        }
    }

    function demand(uint _amount) public{
        require(registered[msg.sender] != 0, "Your address has not been registered.");
        updateState();
        uint8 selector = uint8((epoch + 1) % 2);
        require(userList[registered[msg.sender]].demandEpoch[selector] < epoch, "You have already made a demand in this epoch.");
        
        userList[registered[msg.sender]].demandEpoch[selector] = epoch;
        userList[registered[msg.sender]].demanded[selector] = _amount * units;

            if(resetEpoch < epoch){
                numberOfDemands[selector] = 1;
                resetEpoch = epoch;
            }
            
            else numberOfDemands[selector]++;
    }

   function claim() public{
       updateState();
       uint8 selector = uint8(epoch % 2);
       require(userList[registered[msg.sender]].demandEpoch[selector] == epoch - 1, "You have not made demands in the last epoch.");
       require(capacity != 0, "The capacity has been depleted for this epoch.");
       require(userList[registered[msg.sender]].demanded[selector] > 0, "You claimed all your demands");

       if(userList[registered[msg.sender]].claimEpoch == epoch){        //user made a claim in this epoch
           require(userList[registered[msg.sender]].claimRound < round, "You have already claimed your share for this round!");
           userList[registered[msg.sender]].claimRound = round;
        }

       else{                                                            //new epoch has started since the user's last claim, so update
           userList[registered[msg.sender]].claimEpoch = epoch;
           userList[registered[msg.sender]].claimRound = round;
        }

       if(userList[registered[msg.sender]].demanded[selector] <= share){
           userList[registered[msg.sender]].balance += userList[registered[msg.sender]].demanded[selector];
           capacity -= userList[registered[msg.sender]].demanded[selector];
           userList[registered[msg.sender]].demanded[selector] = 0;
           numberOfDemands[selector]--;
        }

       else{
           userList[registered[msg.sender]].balance += share;
           userList[registered[msg.sender]].demanded[selector] -= share;
           capacity -= share;
        }
   }
   function viewBalance(uint _user) public view returns(uint){
       return userList[_user].balance;
   }
}

