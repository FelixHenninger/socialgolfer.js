# socialgolfer.js

__An implementation of the [greedy randomized adaptive search procedure
(GRASP) algorithm](http://metalevel.at/sgpgreedy.pdf) for the [social golfer
problem](http://mathworld.wolfram.com/SocialGolferProblem.html) in
[CoffeeScript](http://coffeescript.org/).__

The [social golfer problem](http://web.archive.org/web/20050308115423/http://www.icparc.ic.ac.uk/~wh/golf/),
which is a generalization of [Kirkman's schoolgirl
problem](https://en.wikipedia.org/wiki/Kirkman's_schoolgirl_problem), deals with
the issue of creating *g* groups of *p* individuals (golfers, girls or the
like), *w* times, with the constraint that no pair of individuals is sorted into
a group twice. Both are problems of combinatorics that are fairly complex to
solve ([Triska, 2008](http://metalevel.at/mst.pdf)).

This package provides a CoffeeScript/JavaScript implementation of the greedy
randomized adaptive search procedure due to [Triska & Musliu
(2012)](http://metalevel.at/sgpgreedy.pdf), which is a highly efficient method
of solving this set of problems.

## Usage example

[Kirkman's schoolgirl
problem](https://en.wikipedia.org/wiki/Kirkman's_schoolgirl_problem) can be
solved using the following set of commands:

```javascript
const g = require('./grasp.js')

// Find a proposal for five groups of three individuals over seven days
const proposal = g.grasp(5, 3, 7)
// an additional 'iterations' parameter sets the maximum number
// of iterations after which to terminate search (by default 10000)
// -> Found solution after 5918 iterations

console.log(proposal.evaluation())
// Computes the number of scheduling
// conflicts present in the current proposal
// -> 0

console.log(proposal.state)
// Returns a nested array of weeks,
// containing groups of numbered 'golfers'
// [
// [ [ 10, 4, 0 ],
//   [ 12, 9, 3 ],
//   [ 1, 14, 7 ],
//   [ 8, 5, 11 ],
//   [ 2, 13, 6 ] ],
// [ [ 3, 4, 13 ],
//   [ 0, 11, 9 ],
//   [ 6, 14, 5 ],
//   [ 7, 10, 12 ],
//   [ 1, 8, 2 ] ],
// [ [ 10, 14, 11 ],
//   [ 7, 3, 6 ],
//   [ 8, 12, 4 ],
//   [ 5, 0, 2 ],
//   [ 9, 1, 13 ] ],
// [ [ 2, 4, 7 ],
//   [ 11, 12, 1 ],
//   [ 3, 10, 5 ],
//   [ 14, 0, 13 ],
//   [ 8, 9, 6 ] ],
// [ [ 5, 12, 13 ],
//   [ 4, 9, 14 ],
//   [ 11, 2, 3 ],
//   [ 6, 10, 1 ],
//   [ 8, 0, 7 ] ],
// [ [ 12, 0, 6 ],
//   [ 10, 9, 2 ],
//   [ 13, 11, 7 ],
//   [ 1, 5, 4 ],
//   [ 3, 8, 14 ] ],
// [ [ 5, 7, 9 ],
//   [ 4, 6, 11 ],
//   [ 10, 8, 13 ],
//   [ 2, 12, 14 ],
//   [ 1, 0, 3 ] ]
// ]
```

## Caveats

Note that (to the author's knowledge) it is not presently possible to determine
the highest possible number *w* for given values of *g* and *p*, except for
some trivial bounds (please consult [Warwick Harvey's notes on the state of the
art](http://web.archive.org/web/20050308115423/http://www.icparc.ic.ac.uk/~wh/golf/)).

For this reason, and because the search is non-deterministic, the algorithm may
not actually provide a complete solution when it hits the maximum number of
iterations (and might not ever be able provide a solution). Please do not forget
to check the evaluation function for every proposal you compute!

Also, please note that this implementation is vastly slower (by approximately
two orders of magnitude) than that of Markus Triska, which is written in
Prolog/C++. It does, however, find easy solutions quickly, and approximate hard
ones, which is what it was built for.
