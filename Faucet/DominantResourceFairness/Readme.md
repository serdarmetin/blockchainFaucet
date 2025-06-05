This is an initial implementation of an experimental blockchain faucet, managing multiple resource types according to the Dominant Resource Fairness (DRF) distribution scheme.

The original DRF algorithm calculates the shares over normalised demand vectors for each user, assuming that the normalised demand vector corresponds to a unit task. DRF iterates over the list of demand vectors and allocates one task to the least allocated user, and then reiterates with the updated allocation statuses, until at least one resource is exhausted.

The present algorithm differs from DRF for calculating the maximum allocatable dominant share with Max-min Fairness (MF) distribution scheme over the dominant share demands of users, and in turn, calculating the other shares for each user by conserving their relative ratio to the dominant share. In the MF distribution step, percantage demands are used and distributed against a hundred percent capacity. This is appropriate, since if every user has the same resource type as the dominant share, this type will go under an ordinary MF distribution, only over values converted to percentages in the process. Otherwise, since by definition the remaining resources are smaller in size with respect to the dominant share, their sum will not exceed hundred per cent.

Autonomous Max-min Fairness (AMF) has been utilised as the MF subroutine in the implementation.

The correctness of the code and the and correspondence of the algorithm to DRF has not been cross-checked with simulation, and the gas cost performance tests has not been run on a sufficient variety of parameters yet. 
