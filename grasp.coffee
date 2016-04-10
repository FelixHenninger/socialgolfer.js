# Copyright 2016 Felix Henninger
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

_ = require 'lodash'

# Create empty matrices
matrix = (n, fill=true, diag=false) ->
  if fill != null
    o = Array(n).fill().map(() -> Array(n).fill(fill))
  else
    o = Array(n).fill().map(() -> Array(n))

  # Fill diagonal
  if diag != null
    for i in [0..(n-1)]
      o[i][i] = diag

  o

pairs = (elements) ->
  for a, i in elements[..-1]
    for b in elements[(i+1)..]
      yield [a, b]

  return

# Optimized implementation of the pairs generator
`
pairs = function*(elements) {
  for (var i = 0; i < elements.length - 1; i++) {
    for (var j = i + 1; j < elements.length; j++) {
      yield [
        elements[i],
        elements[j]
      ]
    }
  }
}
`

class Golf
  constructor: (@g, @p, @w) ->
    @players = @g * @p
    @state = []
    @freedoms = matrix(@players)

  joint_freedom: (pair) ->
    # Compute the joint freedom
    # of a pair of players.
    [a, b] = pair

    if a is b
      return -100

    if not @freedoms[a][b]
      return -10
    else
      return @freedoms[a].reduce(
        # Count a joint freedom if
        # it is present for both.
        (r, v, i) => r + (v and @freedoms[b][i]),
        0
      )

  freedom_matrix: ->
    output = (new Array(@players) for [1..@players])
    for i in _.range @players
      for j in [0..i]
        f = @joint_freedom [i, j]
        output[i][j] = f
        output[j][i] = f

    output

  freedom_list: ->
    f = @freedom_matrix()
    output = []

    for i in [0..(@players-2)]
      for j in [(i+1)..(@players-1)]
        output.push [f[i][j], i, j]

    output.sort().reverse()

  greedy_heuristic: ->
    proposal = []

    for i in _.range @w
      # Create an output array
      week = []

      # Create a set of candiates still to be
      # distributed in a given week
      candidates = new Set(_.range @players)

      # Calculate pairwise freedoms for
      # use in later allocation
      freedoms = @freedom_list()

      # Fill the groups one by one
      for j in _.range @g
        group = []

        # Add pairs to the group, except if there
        # is a single position remaining (i.e. if
        # groups have an odd number of members)
        for pair in _.range Math.ceil(@p/2)
          if @p - (pair + 1) * 2 isnt 1
            # If there are more than two open
            # positions in the group, add a pair
            for f in freedoms
              # Find the pair with the maximum freedom
              # for which both members have not yet been assigned
              [v, p_i, p_j] = f

              if candidates.has(p_i) and candidates.has(p_j)
                # Add the pair to the group, and remove its
                # members from the list of available candiates
                group.push p_i
                group.push p_j
                candidates.delete p_i
                candidates.delete p_j
                @freedoms[p_i][p_j] = false
                @freedoms[p_j][p_i] = false

                # Stop searching
                break
          else
            # Add a single player to the group
            player = _.sample Array.from(candidates.values())
            candidates.delete player
            group.push player

        week.push(group)

      proposal.push(week)

    @state = proposal

  conflict_matrix: ->
    output = matrix(@players, 0, 0)

    for week, i in @state
      for group, j in week
       `for (var p of pairs(group)) {
          var p1 = p[0]
          var p2 = p[1]
          output[p1][p2] += 1
          output[p2][p1] += 1
        }`

    output

  conflicts: ->
    conflict_matrix = @conflict_matrix()
    output = []

    for row, i in conflict_matrix
      for cell, j in row
        if cell > 1
          output.push([i, j])

    output

  evaluation: ->
    conflict_matrix = @conflict_matrix()
    output = 0

    for row, i in conflict_matrix
      for cell, j in row
        if cell > 1
          output += cell - 1

    output

  swap_candidates: (conflicts_only=true)->
    output = []

    # Compute the players currently in conflict positions
    conflict_matrix = @conflict_matrix()
    conflicts = conflict_matrix.map (row) ->
      reducer = (previous, c) ->
        previous or c > 1

      row.reduce reducer, false

    conflicts = conflicts.map (p, i) ->
      if p then i else -10

    conflicts = conflicts.filter (i) -> i >= 0
    conflicts = new Set(conflicts)

    # Go through the weeks looking for swap candidates
    for week, week_n in @state
      for group, group_n in week
        for other_group, other_group_n in week.slice group_n + 1
          other_group_n += group_n + 1

          for player_a, player_a_n in group
            for player_b, player_b_n in other_group

              #if not conflicts_only or conflict_matrix[player_a][player_b] > 1
              if not conflicts_only or conflicts.has(player_a) or conflicts.has(player_b)
                candidate = new Golf @g, @p, @w

                # Clone state onto new instance
                # candidate.state = _.clone @state, true
                # candidate.state = @state.slice()
                candidate.state = @state.map (w) -> w.map((g) -> g.slice())

                #console.log 'state', candidate.state
                #console.log 'week_n', week_n
                #console.log 'group_n', group_n
                #console.log 'player_a_n', player_a_n
                #console.log 'other_group_n', other_group_n
                #console.log 'player_b_n', player_b_n

                # Perform swap
                candidate.state[week_n][group_n][player_a_n] = player_b
                candidate.state[week_n][other_group_n][player_b_n] = player_a

                #console.log 'swapped state', candidate.state

                # Sort players
                if player_a < player_b
                  [temp_player_a, temp_player_b] = [player_b, player_a]
                else
                  [temp_player_a, temp_player_b] = [player_a, player_b]

                output.push [
                  candidate,
                  candidate.evaluation(),
                  [week_n, temp_player_a, temp_player_b]
                ]

    output

flatten_instance = (g, p, w) ->
  (w - 1) * g * p + (g - 1) * p + (p - 1)

grasp = (g, p, w, iterations=10000) ->

  proposal = new Golf g, p, w
  proposal.greedy_heuristic()

  # Initialize convergence criterion
  best_f = Infinity
  last_f = Infinity
  stable_iterations = 0

  # Initialize tabu list
  tabu_swaps = []

  for i in _.range(iterations)
    # Compute potential swaps and outcomes
    candidates = proposal.swap_candidates()

    # Save ourselves some trouble if the proposal
    # is already perfect
    if proposal.evaluation() isnt 0

      # Extract evaluation for each candidate
      candidate_evaluations = candidates.map (c) -> c[1]
      best_evaluation = Math.min(candidate_evaluations...)

      # Find the best-evaluated candidates
      best_candidates = candidates
        .filter (c) ->
          candidate_f = c[1]
          candidate_f <= best_evaluation and
            (candidate_f < best_f or not _.includes(tabu_swaps, c[2]))

      [candidate, f, swap] = _.sample best_candidates
      #[candidate, f, swap] = best_candidates[0]

      # Output debug messages
      #console.log f
      #console.log candidate.state

      # Add swap to tabu list
      tabu_swaps.push swap

      # Remove the swap that has been in the tabu list for longest
      if tabu_swaps.length > 10
        tabu_swaps.shift()

      if f < best_f
        best_f = f

      # If candidate is an improvement over status quo,
      # adopt it as the new proposal
      if f < last_f
        proposal = candidate
        last_f = f

      # If no improvment has been made for more than
      # four iterations, swap two positions at random
      else if stable_iterations >= 4 and f > 0
        for i in _.range(2)
          [random_candidate, f, swap] = _.sample candidates
          proposal = random_candidate
          tabu_swaps.push swap
          candidates = proposal.swap_candidates(false)

        last_f = f

        stable_iterations = 0
      else
        stable_iterations += 1

      # Debug output
      if i % 100 == 0
        console.log 'current / overall best fit -', best_evaluation, '/', best_f

      # Stop if a solution is found
      if f is 0
        console.log 'Found solution after', i, 'iterations'
        break

  return proposal

print_matrix = (m) ->
  for row in m
    console.log row

module.exports =
  Golf: Golf
  matrix: matrix
  print_matrix: print_matrix
  grasp: grasp
  pairs: pairs
