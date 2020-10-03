pragma solidity ^0.5.13;


contract Faucet{

    //State variables
    uint units = 1;
    uint epochCapacity = 10000 * units;
    uint epochSpan = 2000;
    uint roundSpan = 500;
    uint precision = 1 szabo;

    address owner;
    uint public offset;
    uint public capacity;
    uint public numberOfUsers;
    uint public unitShare;
    uint public epoch;
    uint public round;
    uint[2] public totalWeight;
    uint public resetEpoch;
    

    struct User{
        address payable userAddress;
        uint userId;
        uint[2] demanded;
        uint totalDemanded;
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

            if(totalWeight[selector] != 0)
                unitShare = capacity * precision / totalWeight[selector];
        }

        //Update only round: round starts from 1 to prevent triggering "already claimed" in the first round
        else if(round != ((block.number - offset) % epochSpan) / roundSpan + 1){

            uint8 selector = uint8(epoch % 2);
            
            round = ((block.number - offset) % epochSpan) / roundSpan + 1;
            if(totalWeight[selector] != 0)
                unitShare = capacity * precision / totalWeight[selector];
        }
    }

    function demand(uint _amount) public{
        require(registered[msg.sender] != 0, "Your address has not been registered.");
        updateState();
        uint8 selector = uint8((epoch + 1) % 2);
        require(userList[registered[msg.sender]].demandEpoch[selector] < epoch, "You have already made a demand in this epoch.");
        
        userList[registered[msg.sender]].demandEpoch[selector] = epoch;
        userList[registered[msg.sender]].demanded[selector] = _amount * units;
        userList[registered[msg.sender]].totalDemanded += _amount * units;
        
            if(resetEpoch < epoch){
                totalWeight[selector] = precision / userList[registered[msg.sender]].totalDemanded;
                resetEpoch = epoch;
            }
            
            else totalWeight[selector] += precision / userList[registered[msg.sender]].totalDemanded;
     }

   function claim() public{
       updateState();
       uint8 selector = uint8(epoch % 2);
       require(userList[registered[msg.sender]].demandEpoch[selector] == epoch - 1, "You have not made demands in the last epoch.");
       require(capacity != 0, "The capacity has been depleted for this epoch.");
       uint userShare;
       require(userList[registered[msg.sender]].demanded[selector] > 0, "You claimed all your demands");

       if(userList[registered[msg.sender]].claimEpoch == epoch){        //user made a claim in this epoch
           require(userList[registered[msg.sender]].claimRound < round, "You have already claimed your share for this round!");
           userList[registered[msg.sender]].claimRound = round;
        }

       else{                                                            //new epoch has started since the user's last claim, so update
           userList[registered[msg.sender]].claimEpoch = epoch;
           userList[registered[msg.sender]].claimRound = round;
        }

       if(userList[registered[msg.sender]].demandEpoch[1 - selector] == epoch)
            userShare = (unitShare * (precision / (userList[registered[msg.sender]].totalDemanded - userList[registered[msg.sender]].demanded[1 - selector]))) / precision;
        else userShare = (unitShare * (precision / userList[registered[msg.sender]].totalDemanded)) / precision;

       if(userList[registered[msg.sender]].demanded[selector] <= userShare){
           userList[registered[msg.sender]].balance += userList[registered[msg.sender]].demanded[selector];
           capacity -= userList[registered[msg.sender]].demanded[selector];
           userList[registered[msg.sender]].demanded[selector] = 0;

           if(userList[registered[msg.sender]].demandEpoch[1 - selector] == epoch)
                totalWeight[selector] -= userList[registered[msg.sender]].totalDemanded - userList[registered[msg.sender]].demanded[1 - selector];
            else totalWeight[selector] -= userList[registered[msg.sender]].totalDemanded;
           
        }

       else{
           userList[registered[msg.sender]].balance += userShare;
           userList[registered[msg.sender]].demanded[selector] -= userShare;
           capacity -= userShare;
        }
   }
   function viewBalance(uint _user) public view returns(uint){
       return userList[_user].balance;
   }
}
