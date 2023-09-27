The files present some redundant tables demonstrating the fact that the number of users is not a variable effecting the performance of QMF.

The file results\_q\_10.xlsx contains tests with different numbers of users using a system of QMF with quanta 10, and results\_q\_10.xlsx with quanta 1000. All the tests in the former file has been carried out with randomly generated demands. The demands in the first six tabs of the latter file, likewise are generated randomly.

Although it is apparent in the first six tabs, in order for it to be *conclusive*, 4 more experiments are carried out to demonstrate the fact. The setting of each is as follows:

Demand 1		: 1000 users all with demands equal to 1; the capacity is equal to 1000

Cost Minimised 1	: 1000 users 999 with demands equal to 1 and 1 with demand equal to 2; the capacity is equal to 1000

Cost Minimised 2	: 2000 users 1999 with demands equal to 1 and 1 with demand equal to 2; the capacity is equal to 2000

Cost Maximised	: 1000 users each demanding its user number (i.e. 1, 2, 3, … , 1000); capacity is equal to 500500.

The distribution of demands determines whether a relatively costly branch of an if statement will be executed or not. If no demand has been done for a given demand volume, that iteration does not update the state. In the first case (Demand 1) since only demand volume 1 has been marked, it executes, and the remaining of the loop takes the low cost branch of the if structure.

In the second and third cases, one more demand volume is marked (i.e. demand volume 2), but since the capacity is exceeded the loop breaks (QuantizedMaxMinFaucet\_v\_2.2.sol, line 114) and the function returns the available share. This is the minimum cost I was able to design. It should be noted that the same design leads to the exact same cost (61217) with 1000 and 2000 users, which is two orders of magnitude lower than an average case even with 10 users (2018601).

In the last case (Cost Maximised) since each demand volume has been marked, and the capacity is adjusted to suffice in order the loop should not break, each iteration takes the costly branch of the if structure and the loop is completed; hence the maximum cost of QMF with quanta equalling 1000.
