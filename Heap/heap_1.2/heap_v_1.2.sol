pragma solidity >=0.4.22 <0.6.0;
contract Faucet {

    struct Node {
        uint demanded;
        uint id;
    }
    
    struct User{
        uint balance;
        address user_address;
    }
 
    address owner;
    mapping(uint => User) Users;             //connect these in
    mapping(address => uint) Registered;     //register function
    Node[] heap;


    constructor() public {
        owner = msg.sender;
    }


    function push(uint value1, uint value2) public{
        heap.push(Node(value1, value2));
        uint i = heap.length - 1;
        uint j = (i-1)/2;
        Node memory temp;
        
        while(i!=0){
            if(heap[i].demanded < heap[j].demanded){

                temp.demanded = heap[i].demanded;
                heap[i].demanded = heap[j].demanded;
                heap[j].demanded = temp.demanded;

                temp.id = heap[i].id;
                heap[i].id = heap[j].id;
                heap[j].id = temp.id;

                i = (i-1)/2;
                j = (i-1)/2;
            }
            
            else break;
        }
        
    }


    function pop() public{
        uint leaf;
        leaf = heap.length - 1;
        require(leaf >= 0, "The heap is empty");

        if(leaf == 0){
            delete heap[leaf];
            heap.length--;
            return;
        }

        uint i = 0;
        uint left = 2*i + 1;
        uint right = 2*i + 2;
        heap[0].demanded = heap[leaf].demanded;
        heap[0].id = heap[leaf].id;
        delete heap[leaf];
        heap.length--;
        leaf--;
        Node memory temp;


        while(left <= leaf){
            if(right <= leaf){
                if(heap[right].demanded < heap[left].demanded){
                   if(heap[i].demanded > heap[right].demanded){
                    
                        temp.demanded = heap[i].demanded;
                        heap[i].demanded = heap[right].demanded;
                        heap[right].demanded = temp.demanded;
                        
                        temp.id = heap[i].id;
                        heap[i].id = heap[right].id;
                        heap[right].id = temp.id;
                       
                        i = 2*i + 2;
                        left = 2*i + 1;
                        right = 2*i + 2;
                        continue;
                    }   
                }
            }

            if(heap[i].demanded > heap[left].demanded){
                    temp.demanded = heap[i].demanded;
                    heap[i].demanded = heap[left].demanded;
                    heap[left].demanded = temp.demanded;
                    
                    temp.id = heap[i].id;
                    heap[i].id = heap[left].id;
                    heap[left].id = temp.id;
                    
                    i = 2*i + 1;
                    left = 2*i + 1;
                    right = 2*i + 2;
            }
            else break;
        }
    }

    function top(uint i) public view returns (uint, uint) {
        require(i < heap.length, "The heap is empty");
        return (heap[i].demanded, heap[i].id);
    }
    
    function size() public view returns (uint){
    return (heap.length);
    }
    
    function emptyHeap() public {
        uint length = heap.length;
        while(length !=0){
            delete heap[length-1];
            heap.length--;
            length--;
            }
    }
}
