pragma solidity ^0.5.13;
contract Heaped{


    function push(uint[] memory _heap, uint _length, uint _value) pure public {
        
        uint i = _length;
        
        _heap[i] = _value;
        
        if(i == 0)
            return;
            
        uint j = (i - 1) / 2;

        while(i != 0){
            if(_heap[i] < _heap[j]){
                
                _heap[i] += _heap[j];
                _heap[j] = _heap[i] - _heap[j];
                _heap[i] -= _heap[j];
 
                i = (i - 1) / 2;
                j = (i - 1) / 2;
            }
            else break;
        }
        return;
    }


    function pop(uint[] memory _heap, uint _length) pure public {
        
        uint leaf = _length - 1;
        
        if(leaf == 0) return;

        uint top = 0;
        uint left = 1;
        uint right = 2;
        
        _heap[top] = _heap[leaf];


        while(left < leaf){
            if(right < leaf){
                if(_heap[right] < _heap[left]){
                   if(_heap[top] > _heap[right]){
                    
                        _heap[top] += _heap[right];
                        _heap[right] = _heap[top] - _heap[right];
                        _heap[top] -= _heap[right];
                        
                        top = 2 * top + 2;
                        left = 2 * top + 1;
                        right = left + 1;
                        continue;
                    }   
                }
            }

            if(_heap[top] > _heap[left]){
                
                _heap[top] += _heap[left];
                _heap[left] = _heap[top] - _heap[left];
                _heap[top] -= _heap[left];
    
                top = 2 * top + 1;
                left = 2 * top + 1;
                right = left + 1;
            }
            
            else break;
        }
    }
}

