
defmodule Gossip do
  def main(args) do

    {numNodes,topology,algorithm} = ParseArgs.getArgs(args)

    IO.puts "building topology"
    BuildTopology.getTopology(numNodes, algorithm, topology)

    IO.puts "starting algorithm:"
    Algo.startAlgo(numNodes, topology, algorithm)

  end


end

# Gossip.main(["100","honeycomb","push-sum"])
