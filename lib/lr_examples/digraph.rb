module LrExamples
  module Digraph
    # &f means that the argument is passed using the ruby block syntax
    # i.e. {}
    # For now this can be mostly ignored as we use it as if it was
    # just another hashmap from edges to some value.
    #
    # To facilitate this ruby allows you to pass in a hash as a block
    # argument using the & operator, and you invoke it using [] rather
    # than ().
    def digraph(relation, edges, &f)
      stack = []
      path = []
      state = {}
      result = {}

      for starting_point in edges
        # The outer loop starts an iteration with the next unvisited
        # edge after the previous starting point has traversed all
        # reachable nodes.
        unless state.key?(starting_point)
          stack.push(starting_point)
          state[starting_point] = 0
        end

        until stack.empty?
          edge = stack.pop()

          if state[edge] == 0
            # Each edge is queued for processing exactly twice. Once
            # when traversing downwards in this branch, doing the
            # initial setup, then again in the other branch when
            # ascending back up to propagate the computed values
            # across the component.
            #
            # Thus the weird step of queueing the same element again
            # immediately after popping it.
            stack.push(edge)
            path.push(edge)

            state[edge] = path.length
            result[edge] = f[edge]

            for other in relation[edge]
              unless state.key?(other)
                state[other] = 0
                stack.push(other)
              end
            end
          else
            for other in relation[edge]
              unless state[other] == 0
                state[edge] = [state[edge], state[other]].min
                result[edge] = result[edge] + result[other]
              end
            end

            # Given how state[edge] is assigned to the minimum of the
            # the current node and its neighbours above, this check
            # should only be true for the first node visited in each
            # SCC.
            if path[state[edge] - 1] == edge
              while true
                popped = path.pop()
                # The state gets set to infinity here so that the edge
                # is never considered for being a part of any other
                # component later. Otherwise the trick with setting
                # the minimum value from neighbours wouldn't work
                # properly.
                state[popped] = Float::INFINITY

                if popped == edge
                  break
                else
                  result[popped] = result[edge]
                end
              end
            end
          end
        end
      end

      result
    end
  end
end
