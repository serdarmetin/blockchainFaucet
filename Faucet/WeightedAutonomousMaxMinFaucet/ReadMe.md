The lines 135-137 in the code has been corrected to subtract "precision divided by the totalDemand", rather than "the absolute totalDemand" value, as pointed out by ChatGPT.

By the time of development and testing, this error did not show up in the results, when the exact inputs were fed into the traditional MF calculator and outputs are checked against.

This is either due to the difference in orders of magnitude between the values multiplied by the precision value (which is a big number) and demand volumes, or, an earlier, correct version of the code was used in the experiments, and it was replaced by the erroneus code, while working on the readability of the code in the staging to the Github process.
