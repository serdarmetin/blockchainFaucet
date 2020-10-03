pragma solidity ^0.5.13;
contract Heaped{

    struct Node {
        uint demanded;
        uint id;
    }
    
    Node[][2] public demandHeap;


    function push(uint8 selector, uint value1, uint value2) public {
        demandHeap[selector].push(Node(value1, value2));
        uint i = demandHeap[selector].length - 1;
        uint j = (i-1)/2;
        Node memory temp;
        
        while(i!=0){
            if(demandHeap[selector][i].demanded < demandHeap[selector][j].demanded){

                temp.demanded = demandHeap[selector][i].demanded;
                demandHeap[selector][i].demanded = demandHeap[selector][j].demanded;
                demandHeap[selector][j].demanded = temp.demanded;

                temp.id = demandHeap[selector][i].id;
                demandHeap[selector][i].id = demandHeap[selector][j].id;
                demandHeap[selector][j].id = temp.id;

                i = (i-1)/2;
                j = (i-1)/2;
            }
            else break;
        }
        
    }


    function pop(uint8 selector) public {
        uint leaf;
        leaf = demandHeap[selector].length - 1;
        require(leaf >= 0, "The heap is empty");

        if(leaf == 0){
            delete demandHeap[selector][leaf];
            demandHeap[selector].length--;
            return;
        }

        uint i = 0;
        uint left = 2*i + 1;
        uint right = 2*i + 2;
        demandHeap[selector][0].demanded = demandHeap[selector][leaf].demanded;
        demandHeap[selector][0].id = demandHeap[selector][leaf].id;
        delete demandHeap[selector][leaf];
        demandHeap[selector].length--;
        leaf--;
        Node memory temp;


        while(left <= leaf){
            if(right <= leaf){
                if(demandHeap[selector][right].demanded < demandHeap[selector][left].demanded){
                   if(demandHeap[selector][i].demanded > demandHeap[selector][right].demanded){
                    
                        temp.demanded = demandHeap[selector][i].demanded;
                        demandHeap[selector][i].demanded = demandHeap[selector][right].demanded;
                        demandHeap[selector][right].demanded = temp.demanded;
                        
                        temp.id = demandHeap[selector][i].id;
                        demandHeap[selector][i].id = demandHeap[selector][right].id;
                        demandHeap[selector][right].id = temp.id;
                       
                        i = 2*i + 2;
                        left = 2*i + 1;
                        right = 2*i + 2;
                        continue;
                    }   
                }
            }

            if(demandHeap[selector][i].demanded > demandHeap[selector][left].demanded){
                    temp.demanded = demandHeap[selector][i].demanded;
                    demandHeap[selector][i].demanded = demandHeap[selector][left].demanded;
                    demandHeap[selector][left].demanded = temp.demanded;
                    
                    temp.id = demandHeap[selector][i].id;
                    demandHeap[selector][i].id = demandHeap[selector][left].id;
                    demandHeap[selector][left].id = temp.id;
                    
                    i = 2*i + 1;
                    left = 2*i + 1;
                    right = 2*i + 2;
            }
            else break;
        }
    }
    
    function emptyHeap(uint8 selector) public {
        delete(demandHeap[selector]);
    }
}
