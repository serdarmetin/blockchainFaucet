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
    mapping(uint => User) Users;             //connect these in
    mapping(address => uint) Registered;     //register function
    Node[] heap;


    constructor() public {
        owner = msg.sender;
    }


    function push(uint value1, uint value2) public{
        Node memory temp = Node(value1,value2);
        heap.push(temp);
        uint i = heap.length - 1;
        
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
        require(heap.length > 0);
        uint i = 0;
        heap[0].demanded = heap[heap.length -1].demanded;
        heap[0].id = heap[heap.length - 1].id;
        delete heap[heap.length - 1];
        heap.length--;


        while((2*i) + 1 < heap.length){
            
            if((2*i) + 2 < heap.length){
                if(heap[(2*i) + 2].demanded < heap[(2*i) + 1].demanded && heap[i].demanded > heap[(2*i) + 2].demanded){
                    heap[i].demanded += heap[(2*i) + 2].demanded;
                    heap[(2*i) + 2].demanded = heap[i].demanded - heap[(2*i) + 2].demanded;
                    heap[i].demanded -= heap[(2*i) + 2].demanded;
                    
                    heap[i].id += heap[(2*i) + 2].id;
                    heap[(2*i) + 2].id = heap[i].id - heap[(2*i) + 2].id;
                    heap[i].id -= heap[(2*i) + 2].id;
                   
                    i = (2*i) + 2;
                }   
                
                else if(heap[i].demanded > heap[(2*i) + 1].demanded){
                    heap[i].demanded += heap[(2*i) + 1].demanded;
                    heap[(2*i) + 1].demanded = heap[i].demanded - heap[(2*i) + 1].demanded;
                    heap[i].demanded -= heap[(2*i) + 1].demanded;
                    
                    heap[i].id += heap[ (2*i) + 1].id;
                    heap[(2*i) + 1].id = heap[i].id - heap[(2*i) + 1].id;
                    heap[i].id -= heap[(2*i)+1].id;
                    
                    i = (2*i) + 1;
                }
                else break;
            }
            
            
            else if(heap[i].demanded > heap[(2*i) + 1].demanded){

                heap[i].demanded += heap[(2*i) + 1].demanded;
                heap[(2*i) + 1].demanded = heap[i].demanded - heap[(2*i) + 1].demanded;
                heap[i].demanded -= heap[(2*i) + 1].demanded;
                
                heap[i].id += heap[ (2*i) + 1].id;
                heap[(2*i) + 1].id = heap[i].id - heap[(2*i) + 1].id;
                heap[i].id -= heap[(2*i)+1].id;
                
                i = (2*i) + 1;
            }

            else break;
        }
    }

    function top(uint i) public view returns (uint, uint) {
        return (heap[i].demanded, heap[i].id);
    }

}
