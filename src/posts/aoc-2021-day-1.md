---
title: "✨ Advent of Code: Day 1 in Julia"
date: 2021-12-01
tags: ["advent of code", "2021", "julia", "functional programming"]
---

# Introduction
Inspired by the [many](https://www.swyx.io/learn-in-public/) [articles](https://medium.com/my-learning-journal/why-you-should-learn-in-public-4fd3a6239549) about learning in public, I decided to write a blog post about my learnings for the first day of Advent of Code 2021.

Every year, I'm looking forward to participate in [Advent of Code](https://adventofcode.com/). Those daily puzzles are super delightful and it's so rewarding to get a working solution. Though with the rising difficulty it's very hard to nail every challenge all the way to the end but hey at least I've worked on Day 1!

This year, like [last year](https://github.com/mewfree/advent-of-meow-2020), I decided to use [Julia](https://julialang.org/). I like to describe it as "As simple as Python, as fast as C", but there are also some features that I really like (a fast and awesome REPL, pipes (`|>`), vectorized functions...).

# Parsing Input
Parsing input is the first step in solving an Advent of Code puzzle.

My biggest tip about Advent of Code is to test your code against the public (I personally save it in a file `test_input` next to my real, private `input` file).

## Initial Method
By solving [last year's Advent of Code](https://github.com/mewfree/advent-of-meow-2020) in Julia too, I remembered [the method I was using](https://github.com/mewfree/advent-of-meow-2020/blob/main/day-01/solution.jl#L1), which is essentially:
- read file as a string
- split by newline
- for each line parse string as an Integer

```julia
input = open(f->read(f, String), "test_input") |> f->split(f, "\n") |> a->map(s->parse(Int, s), a)
```

But I was not satisfied with it and kept feeling like there must be a better way...

## Cleaner Method
After some research that's how I found out about [Delimited Files](https://docs.julialang.org/en/v1/stdlib/DelimitedFiles/), part of Julia's standard library!
More specifically, the `readdlm` method that allows to read a file as a matrix while also handling parsing to integers or floats at the same time.

```julia
julia> using DelimitedFiles

julia> input = readdlm("test_input", Int)
10×1 Matrix{Int64}:
 199
 200
 208
 210
 200
 207
 240
 269
 260
 263
```

What we want is a vector though (what in most other languages would be called an array or list, essentially a 1-Dimension Matrix in Julia's perspective), but the `vec` function easily handles that for us:
```julia
julia> input = readdlm("test_input", Int) |> vec
10-element Vector{Int64}:
 199
 200
 208
 210
 200
 207
 240
 269
 260
 263
```

# Part 1 Solution
## Map -> Reduce
Alright, now to the good stuff. I won't go over [Day 1's puzzle](https://adventofcode.com/2021/day/1) here, I would recommed you go through it yourself first!
We want to know whether element `n` is lesser than element `n+1`, or actually whether element `n` is greater than element `n-1`.
My first guess is to `map` over the input, using `enumerate` to get the index of the `n`th element, and using that to compare it to the `n-1`th element. A quick [ternary operator](https://docs.julialang.org/en/v1/manual/control-flow/#man-conditional-evaluation) is necessary to handle the case of the first element.

```julia
julia> map(x -> x[1] - 1 == 0 ? false : x[2] > input[x[1] - 1], enumerate(input))
10-element Vector{Bool}:
 0
 1
 1
 1
 0
 1
 1
 1
 0
 1
```

Now that we have a list of booleans (or ones and zeros), a quick reduce allows us to sum up the values:
```julia
julia> reduce(+, map(x -> x[1] - 1 == 0 ? false : x[2] > input[x[1] - 1], enumerate(input)))
7
```

## Zip -> Map -> Sum
By sharing my first solution with my colleagues and reviewing others, I quickly got two feedback:
- `reduce` is not necessary and a simple `sum` should work
- `zip` can be very useful! (I always forget about `zip`...)

```julia
julia> map(((x, y),) -> x < y, zip(input, input[2:end]))
9-element Vector{Bool}:
 1
 1
 1
 0
 1
 1
 1
 0
 1
```

Some explanation of the code above.
This is what zip does:
```julia
julia> zip(input, input[2:end]) |> collect
9-element Vector{Tuple{Int64, Int64}}:
 (199, 200)
 (200, 208)
 (208, 210)
 (210, 200)
 (200, 207)
 (207, 240)
 (240, 269)
 (269, 260)
 (260, 263)
```

Remember that Julia's indexes start at 1, not 0 (similiar to other mathematics-oriented languages like R or MATLAB), meaning that we combine the initial vector with the same vector starting from the 2nd element. The result is a vector of tuples.

The `((x, y),) -> x < y` notation allows to destructurate the tuple inside the list of parameters, instead of having to do something like `x -> x[1] < x[2]` (which you might consider cleaner, but I don't, even though it's technically terser).

Piping a `sum` at the end:
```julia
julia> map(((x, y),) -> x < y, zip(input, input[2:end])) |> sum
7
```

## Diff
I was pretty satisfied with this solution, but as I looked around the amazing [/r/adventofcode](https://www.reddit.com/r/adventofcode/)'s [solution megathread](https://www.reddit.com/r/adventofcode/comments/r66vow/2021_day_1_solutions/), I saw someone using a simply `diff` function in R.

And to my pleasant surprise, Julia has [a `diff` function](https://docs.julialang.org/en/v1/base/arrays/#Base.diff) too!
```julia
julia> diff(input)
9-element Vector{Int64}:
   1
   8
   2
 -10
   7
  33
  29
  -9
   3
```

It automatically calculates the difference between "next" elements of arrays/vectors.

`Map`ing over this result to check if the result is positive:
```julia
julia> map(x -> x > 0, diff(input))
9-element Vector{Bool}:
 1
 1
 1
 0
 1
 1
 1
 0
 1
```

And once again, piping a `sum` at the end:
```julia
julia> map(x -> x > 0, diff(input)) |> sum
7
```

## Final Solution
To recap, this gives us a one-liner:
```julia
julia> readdlm("test_input", Int) |> vec |> v->map(x -> x > 0, diff(v)) |> sum
7
```

# Part 2 Solution
Not much evolution here, but we're going to benefit from everything we learnt in part 1.

We need to create sliding windows of size 3. I didn't feel like implement it myself as I don't enjoy reinventing the wheel, so looked around for an available method.

The [`Partition`](https://juliafolds.github.io/Transducers.jl/dev/reference/manual/#Transducers.Partition) method from [Transducers.jl](https://github.com/JuliaFolds/Transducers.jl) looked like it would work.

```julia
julia> using Transducers

julia> windows = input |> Transducers.Partition(3; step = 1) |> Map(copy) |> collect
8-element Vector{Vector{Int64}}:
 [199, 200, 208]
 [200, 208, 210]
 [208, 210, 200]
 [210, 200, 207]
 [200, 207, 240]
 [207, 240, 269]
 [240, 269, 260]
 [269, 260, 263]
```
Nice

Using the [dot syntax to vectorize function](https://docs.julialang.org/en/v1/manual/functions/#man-vectorized), we can get the sum of each window:
```julia
julia> sum.(windows)
8-element Vector{Int64}:
 607
 618
 618
 617
 647
 716
 769
 792
```

And we can still use the same workflow as part 1 to calculate differences and how many times there was an increase in value.

Or if you really want a one-liner...
```julia
julia> readdlm("test_input", Int) |> vec |> Transducers.Partition(3; step = 1) |> Map(copy) |> collect |> w->map(x -> sum(x), w) |> v->map(x -> x > 0, diff(v)) |> sum
5
```

# Conclusion
Here's the full script that is [available on GitHub](https://github.com/mewfree/advent-of-meow-2021/blob/main/day-01/solution.jl):
```julia
using DelimitedFiles
using Transducers

input = readdlm("input", Int) |> vec
compare(vec) = map(x -> x > 0, diff(vec))
windows = input |> Transducers.Partition(3; step = 1) |> Map(copy) |> collect

println("Part 1: ", input |> compare |> sum)
println("Part 2: ", sum.(windows) |> compare |> sum)
```

Pretty satisfied with this! I don't think there's much left to improve.

Main learnings for me:
- `readdlm` is super useful
- `zip` can be cleaner than fiddling with `enumerate` and indexes
- vectorized functions rock!

I don't think it will be sustainable for me to keep blogging about next Advent of Code puzzles, but hope this was an interesting read and that you learnt something.
