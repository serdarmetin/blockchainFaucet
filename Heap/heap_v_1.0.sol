pragma solidity >=0.4.22 <0.6.0;
contract Faucet {

    struct Node {
        uint demanded;
        uint id;
    }
    
    struct User{
        uint balance;
        address id;
    }
 
    address owner;
    mapping(int => User) Users;             //make sure
    mapping(address => User) Registered;    //these two are connected
    Node[] heap;


    constructor() public {
        owner = msg.sender;
    }


    function push(uint value1, uint value2) public{
        Node memory temp = Node(value1,value2);
        heap.push(temp);
        uint i = heap.length -1;
        
        while(i!=0){
            if(heap[i].demanded < heap[(i-1)/2].demanded){
                
                heap[i].demanded += heap[(i-1)/2].demanded;
                heap[(i-1)/2].demanded = heap[i].demanded - heap[(i-1)/2].demanded;
                heap[i].demanded -= heap[(i-1)/2].demanded;
                
                heap[i].id += heap[(i-1)/2].id;
                heap[(i-1)/2].id = heap[i].id - heap[(i-1)/2].id;
                heap[i].id -= heap[(i-1)/2].id;

                i = (i-1)/2;
            }
            
            else break;
        }
        
    }


    function pop() public{
        uint i = 0;
        uint n = heap.length - 1;
        heap[0].demanded = heap[n].demanded;
        heap[0].id = heap[n].id;
        heap.length--;
        n--;
        
        while((2*i) + 1 <= n){
            if(heap[i].demanded > heap[ (2*i) + 1 ].demanded){

                heap[i].demanded += heap[ (2*i) + 1 ].demanded;
                heap[(2*i)+1].demanded = heap[i].demanded - heap[(2*i)+1].demanded;
                heap[i].demanded -= heap[(2*i)+1].demanded;
                
                heap[i].id += heap[ (2*i) + 1 ].id;
                heap[(2*i)+1].id = heap[i].id - heap[(2*i)+1].id;
                heap[i].id -= heap[(2*i)+1].id;
                
                i = (2*i) + 1;
            }

            else if((2*i) + 2 <= n){
                if(heap[i].demanded > heap[ (2*i) + 2 ].demanded){
                    heap[i].demanded += heap[ (2*i) + 1 ].demanded;
                    heap[(2*i)+1].demanded = heap[i].demanded - heap[(2*i)+1].demanded;
                    heap[i].demanded -= heap[(2*i)+1].demanded;
                    
                    heap[i].id += heap[(2*i) + 2].id;
                    heap[(2*i)+2].id = heap[i].id - heap[(2*i)+2].id;
                    heap[i].id -= heap[(2*i)+2].id;
                   
                    i = (2*i) + 2;
                }
            }
            else break;
        }
    }

    function top(uint i) public view returns (uint, uint) {
        return (heap[i].demanded, heap[i].id);
    }

}

