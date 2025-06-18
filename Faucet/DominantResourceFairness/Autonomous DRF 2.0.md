Autonomous Dominant Resource Fairness is a blockchain implementation of Dominant Resource Fairness (Ghodsi et al., 2011), on the demand, claim and share calculation structure developed in Autonomous Max-min Fairness, which also can be accessed in lateral branches of this repository.

Unlike version 1.4, ADRF 2.0 follows the exact demand structure of the original algorithm. The calculation of shares is based on Extended DRF of Parkes et al. (2015).

The code has not been tested yet, and for all practical reasons, it is fair to assume that the floating point arithmetics should be debugged before being ready to use.

References:

Ghodsi, A., Zaharia, M., Hindman, B., Konwinski, A., Shenker, S., & Stoica, I. (2011). Dominant resource fairness: Fair allocation of multiple resource types. In 8th USENIX symposium on networked systems design and implementation (NSDI 11).

Parkes, D. C., Procaccia, A. D., & Shah, N. (2015). Beyond dominant resource fairness: Extensions, limitations, and indivisibilities. ACM Transactions on Economics and Computation (TEAC), 3(1), 1-22.
