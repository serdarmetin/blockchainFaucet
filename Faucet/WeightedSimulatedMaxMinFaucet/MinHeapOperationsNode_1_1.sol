//  Volume is key and weight is value

pragma solidity ^0.5.13;
pragma experimental ABIEncoderV2;

contract Heaped{

    struct node {
        uint volume;
        uint weight;
    }


    function push(node[] memory _heap, node memory _node) pure public {
        
        uint i = _heap.length;
        
        _heap[i] = _node;
        
        if(i == 0)
            return;
            
        uint j = (i - 1) / 2;

        while(i != 0){
            if(_heap[i].volume < _heap[j].volume){
                
                (_heap[i].volume, _heap[j].volume) = (_heap[j].volume, _heap[i].volume);
                (_heap[i].weight, _heap[j].weight) = (_heap[j].weight, _heap[i].weight);

                i = (i - 1) / 2;
                j = (i - 1) / 2;
            }
            else break;
        }
        return;
    }


    function pop(node[] memory _heap) pure public {
        
        uint leaf = _heap.length - 1;
        
        if(leaf == 0) return;

        uint top = 0;
        uint left = 1;
        uint right = 2;
        
        _heap[top] = _heap[leaf];


        while(left < leaf){
            if(right < leaf){
                if(_heap[right].volume < _heap[left].volume){
                   if(_heap[top].volume > _heap[right].volume){
                    
                        (_heap[top].volume, _heap[right].volume) = (_heap[right].volume, _heap[top].volume);
                        (_heap[top].weight, _heap[right].weight) = (_heap[right].weight, _heap[top].weight);

                        top = 2 * top + 2;
                        left = 2 * top + 1;
                        right = left + 1;
                        continue;
                    }   
                }
            }

            if(_heap[top].volume > _heap[left].volume){
                
                        (_heap[top].volume, _heap[left].volume) = (_heap[left].volume, _heap[top].volume);
                        (_heap[top].weight, _heap[left].weight) = (_heap[left].weight, _heap[top].weight);
    
                top = 2 * top + 1;
                left = 2 * top + 1;
                right = left + 1;
            }
            
            else break;
        }
    }
}

