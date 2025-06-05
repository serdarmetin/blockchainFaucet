This is an initial implementation of an experimental blockchain faucet, managing multiple resource types according to the Dominant Resource Fairness (DRF) distribution scheme.

The original DRF algorithm calculates the shares over normalised demand vectors for each user, assuming that the normalised demand vector corresponds to a unit task. DRF iterates over the list of demand vectors and allocates one task to the least allocated user, and then reiterates with the updated allocation statuses, until at least one resource is exhausted.

The present algorithm differs from DRF for calculating the maximum allocatable dominant share with Max-min Fairness distribution scheme over the dominant share demands of users, and in turn, calculating the other shares for each user by conserving their relative ratio to the dominant share. Autonomous Max-min Fairness (AMF) has been utilised as a subroutine in the implementation.

The correctness of code has not been cross-checked with simulation and the tests on all necessary parameters has not been completed yet.
