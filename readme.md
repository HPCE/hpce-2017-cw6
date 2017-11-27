HPCE 2017 CW6
=============

The goal of this coursework is to take an existing library
called [TestU01](http://simul.iro.umontreal.ca/testu01/tu01.html),
and parallelise, optimise, or otherwise accelerate it.

TestU01 is used for testing random number generators (RNG), and
tries to empirically look for statistical flaws in the output of
an RNG that are not likely to occur by chance. As RNGs have improved,
the number of samples needed to show non-randomness has
also increased, so these days we might need to look at 2^38 or
more random numbers before seeing failures, and apply many different
types of statistical tests.  But because the random numbers are often
used in massively parallel compute simulations, the number of
random numbers consumed in one simulation is growing to 2^48 or
more, so it is important to look for flaws in even larger samples.

There is substantial documentation for TestU01 in the included
pdfs. It covers the main APIs, design intent, and also the details
of the statistics. It is up to you to decide how deep you want
to go. Originally TestU01 was single-threaded C, but it has been
converted to C++ and made thread-safe. The only remaining unsafe
part I'm aware of is the `unif01_Gen` struct - **you cannot safely use
the same `unif01_Gen` class from two different tasks or threads
at the same time.** You can use two _different_ instances of
`unif01_Gen` at the same time, but they must be seperate.

Your goal is to optimise the TestU01 library with three use-cases
in mind (or two for a pair):

- Certification: making sure that an RNG can pass a relatively slow
  standardised test-suite, in this case the Crush benchmark. The
  metric is simply the execution time (latency).
  
- Search: evaluating many different RNG instances in order to search
  for good RNG parameters. The metric is how many times the SmallCrush
  benchmark can be executed per second.

- Stress testing : Trying to test as large a sample
  as possible within a time budget, using the benchmark Rabbit. Given a
  time-budget `t`, your program should respond within 0.5 sec with a bid size `n`.
  If the actual execution time is `g`, then the metric is `min(1,exp(-g/t))*log2(n)`.

As part of the input to the use-cases there is also an RNG source
called the "workload" (see `include/workload.hpp`). This is code
supplied by the user, and not under your control. So the inputs to
an application are:

- Your (potentially customised) TestU01 library

- Your (potentially customised) driver program

- An externally sourced workload containing the RNG(s)

There is an example workload in the `workloads` directory called
`workload_std.cpp`, which exposes two random number generators
from the C++ standard library. The default makefile knows
how to build `bin/${use-case}_${workload}` from `drivers/driver_${use-case}.cpp`
and `workload/workload_${workload}.cpp`.

Stress testing for `std` workload:
```
$ make bin/stress_std
$ bin/stress_std
```

Stress testing for `std` workload:
```
$ make bin/search_std
$ bin/stress_std
```

Certification for `std` workload:
```
$ make bin/certify_std
$ bin/certify_std
```

Compilation for assesment will consist of copying a workload
into `workloads`, then running `make bin/{use-case}_{workload}`.
Execution will start from the root directory of the repository,
as in the examples above.

Correctness
-----------

Correctness for statistical testing is quite interesting, as it doesn't
matter which part of an RNG's output stream is tested, as long as each
test only looks at some contiguous and in-order part of the stream. So
if one test consumes `n` random number, then it could consume `x_1,x_2,...x_{n}`,
or `x_{n},x_{n+1},...,x_{2n}` - statistical quality should be invariant
to where you look in the stream, However, it does depend on the order
in which you look, so you can't test `x_1,x_4,x_10,x_3,...` as randomness
also depends on the ordering of the samples.

One approach to correctness is to return bit-exact answers compared to
the sequential version, which makes verification easier. However, it
also limits flexibility and is a bit unrealistic. Instead, as long as
your tests still give the same statistical answer, then it is acceptable.
Each test returns a p-value, and they should behave in a particular
way statistically - if the RNG is passing the test, then they look
like uniform numbers in U(0,1), otherwise they are heavily biased towards
0 or 1. I'll be testing your implementations on different workloads,
and have a very good idea of what the distribution of p-values should
look like for each (i.e. I can tune workloads to particular known p-value
distributions), so as long as your tests are statistically plausible
then they are correct.

This gives you the freedom to play around with algorithms and floating-point
issues, but if you want to stick to bit-exact answers that should
work too.

Non thread-safe Bug bounty
----------------------

As far as I'm aware I've eliminated all thread unsafe conditions
from TestU01, but there may still be things lurking. I've done
soak tests on multi-core machines where I run the benchmarks
repeatedly in parallel with themselves, but experience suggests something
else is likely to turn up. To encourage people to share (as this
is particularly difficult to deal with for those weaker on programming),
I'm willing to award up to a 2% bonus (for this coursework) to groups
who find something that is thread unsafe and can point to the problem
area (and ideally a fix). I'm not too worried about latent bugs, or
problems with IO paths that aren't exercised (I'm aware that the
standard report writing is interleaved), but anything that
causes genuine race conditions or thread-safety related crashes
crashes is of particular interest.

General bug-reports and bug-fixes are still very much welcome, but
I particularly want to reward any thread-unsafe parts as they tend
to be difficult to debug and affect many people, and generally
demonstrate the most expertise on the part of those who can find
and fix them.
  
Assessment
----------

The target environment is either a `g3.4xlarge` (note that this is
newer than in previous courseworks), or a `c4.8xlarge`. You
should indicate in `group.md` which one you want to use.

The marks for the coursework are split up into three parts:

- Performance (60%) : How well it does in the two (pairs) or three (triples) use-cases.
                      As before, each pair should nominate two uses-cases.

- Group analsis (20%) : Each group needs to provide two (pairs) or three (triples)
                        suggestions for improvement - see the attached `group.md`.

- Individual analysis (20%) : Each individual should separately submit a 
                       document `reflection.md` via blackboard (this is something that
                       is looking back, so is not included yet).

Getting started
---------------

You may be confused about how to get started. Some suggestions are:

- Compile and run the programs.

- Get some initial high-level profiling, e.g. using perf or gdb

- Try to get a feel for the scaling properties of each use-case.

- Try to work out the _important_ tasks in the program, and
  the flows of data between different tasks.
  
- Brain-storm some possible strategies for improvement, and try to
  identify the effort versus improvement of each.
  
- Allocate strategies to people and get started.
