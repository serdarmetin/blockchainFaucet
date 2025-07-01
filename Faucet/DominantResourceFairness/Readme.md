Autonomous Dominant Resource Fairness (ADRF) is a blockchain resource allocation mechanism which implements an approximation to Dominant Resource Fairness (DRF) allocation Scheme [1], by employing a limited version of Precomputed Dominant Resource Fairness (PDRF) algorithm [2], adapted to the blockchain context, based on Autonomous Max-min Fairness (AMF) structure.

ADRF is a limited version of PDRF, for two reasons:

1 - PDRF requires iterative elimination of the demands with maximum dominant share when a cycle is saturated
2 - PDRF runs the original DRF in its last allocation round

both of which are infeasible in the blockchain context. The first condition can be achieved, but takes several allocation rounds to complete; the second one, we know of no way of implementing, if it is possible (An argument against this was made for a similar condition in [3] for Max-min Fairness).

As such ADRF is short of reaching Pareto Efficiency. Nevertheless, under normal distribution of demands, it comes close to the original algorithm. Unfortunately, we cannot provide a more rigorous proximity measure, for it necessitates a method for the analysis of the algorithm based on the initial distribution of the input, that we are not aware of if there are any.

There are two versions of the algorithm:

ADRF 2.1 takes a single round of distribution, and hands the leftover resources to following same parity distribution epoch, i.e. the second next epoch. This can be implemented to hand over to the immediate next epoch, but it would necessitate the demands and claims be made in a given order. As it is implemented now, demands and claims may be done in any order within a given epoch.

ADRF 2.2 takes an additional round for allocating residual resources from the first round that comes about as a consequence of rounding difference between calculation with cumulative demands versus assignment over individual demands. Similarly, the excess resources are handed over to the epoch after the next.

ADRF 2.2 is mainly for examplification and proof of concept purposes. The experiments we carried out showed that an additional round contributes only a slight improvement to approximate Pareto Efficiency, if any. But it is a prototype for any interested party to implement a version with more allocation rounds, for scenarios where initial distribution of demands is skewed or atypically disperse and the cost of additional rounds is reasonable with respect to the benefits. With some additional effort, iterative exclusion of maximum dominant shares can also be implemented for further approximating PDRF and thus, DRF.

In addition to the overall structure of AMF, which ADRF 2.2 is based on, we needed to include a new funtion, named "refreshDemand()", which the users are expected to execute in the second round to eliminate the saturated demands.

One caveat is that due to the unavailability of floating point variables in Solidity, the precision of the calculation may falter at times, and it can be better calibrated than it is now. It occasionally differs in one or two task allocations than the python implementation, in the second round of claims.

[1] Ghodsi, A., Zaharia, M., Hindman, B., Konwinski, A., Shenker, S., & Stoica, I. (2011). Dominant resource fairness: Fair allocation of multiple resource types. In 8th USENIX symposium on networked systems design and implementation (NSDI 11).

[2] 

[3] Metin, S., & Özturan, C. (2022). Max–min fairness based faucet design for blockchains. Future Generation Computer Systems, 131, 18-27.
