Autonomous Dominant Resource Fairness (ADRF) is a blockchain resource allocation mechanism which implements an approximation to Dominant Resource Fairness (DRF) allocation Scheme [1], by employing Precomputed Dominant Resource Fairness (PDRF) algorithm [2], adapted to the blockchain context, based on Autonomous Max-min Fairness (AMF) structure.

As such ADRF is short of reaching Pareto Efficiency. Nevertheless, under discrete uniform distribution of demands, it comes close to the DRF allocation. A more detailed analysis is available at [2].

There are two versions of the algorithm:

ADRF 2.1 takes a single round of distribution, and hands the leftover resources to following same parity distribution epoch, i.e. the second next epoch. This can be implemented to hand over to the immediate next epoch, but it would necessitate the demands and claims be made in a given order. As it is implemented now, demands and claims may be done in any order within a given epoch.

ADRF 2.2 takes an additional round for allocating residual resources from the first round that comes about as a consequence of rounding difference between calculation with cumulative demands versus assignment over individual demands. Similarly, the excess resources are handed over to the epoch after the next.

ADRF 2.2 is mainly for examplification and proof of concept purposes. The experiments we carried out showed that under discrete uniform distribution, an additional round contributes only a slight improvement to approximate Pareto Efficiency, if any. But it is a prototype for any interested party to implement a version with more allocation rounds, for scenarios where initial distribution of demands is skewed or atypically disperse and the cost of additional rounds is reasonable with respect to the benefits. With some additional effort, iterative exclusion of maximum dominant shares can also be implemented for further approximating DRF.

In addition to the overall structure of AMF, which ADRF 2.2 is based on, we needed to include a new funtion, named "refreshDemand()", which the users are expected to execute in the second round to eliminate the saturated demands.

[1] Ghodsi, A., Zaharia, M., Hindman, B., Konwinski, A., Shenker, S., & Stoica, I. (2011). Dominant resource fairness: Fair allocation of multiple resource types. In 8th USENIX symposium on networked systems design and implementation (NSDI 11).

[2] 

[3] Metin, S., & Özturan, C. (2022). Max–min fairness based faucet design for blockchains. Future Generation Computer Systems, 131, 18-27.
