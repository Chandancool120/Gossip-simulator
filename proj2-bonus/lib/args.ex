defmodule ParseArgs do
  def getArgs(args) do
    numNodes  =  Enum.at(args,0) |> String.to_integer()
    failNodes  =  Enum.at(args,1) |> String.to_integer()
    topology  =  Enum.at(args,2) |> getTopology()
    algorithm =  Enum.at(args,3) |> getAlgorithm()
    {numNodes,failNodes,topology,algorithm}
  end


  def getTopology(topology) do
      case topology do
        "full" -> :full
        "line" -> :line
        "rand2D" -> :rand2D
        "3Dtorus" -> :torus3D
        "honeycomb" -> :honeycomb
        "randhoneycomb" -> :randhoneycomb
      end
  end


  def getAlgorithm(algorithm) do
      case algorithm do
        "gossip"   -> :gossip
        "push-sum" -> :pushsum
      end
  end


end
