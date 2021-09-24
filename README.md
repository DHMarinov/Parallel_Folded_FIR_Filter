# Parallel_Folded_FIR_Filter
Implementation of a parallel folded FIR filter.

Important!
One thing that I forgot to mention in the video is - the pre-adder can cause overflow/underflow issues if the amplitude of the input is too big.
Therefore one way to ensure this never happens is to right-shift the input by one bit (i.e. divide the input by 2).

