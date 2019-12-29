defmodule Algo do

  def startAlgo(numNodes, failNodes,topology, :gossip) do
      IO.puts "start gossip"
      failNodes = Enum.to_list(1..failNodes)
      failNodes = Enum.map(failNodes,fn(x)->
        Enum.random(Enum.to_list(1..numNodes))
      end)
      table = :ets.new(:table, [:named_table, :public])
      :ets.insert_new(:table,{"failnodes",failNodes})
      IO.inspect failNodes
      Enum.each(failNodes,fn(y)->
        adjList = ActorNode.getAdjList(String.to_atom("node"<>Integer.to_string(y)))
        Enum.each(adjList,fn(x)->
          ActorNode.updateAdjNodes(String.to_atom("node"<>Integer.to_string(y)),adjList--[x])
        end)
      end)
      Process.sleep(5000)
      {time,_} = :timer.tc(fn-> startGossip(numNodes,failNodes) end)
      IO.puts "Gossip finished, every node gets the rumor 10 times, time taken for gossip: #{time}us"
  end



  def startAlgo(numNodes, failNodes, topology, :pushsum) do
    IO.puts("Starting...")
    numNodes = if Atom.to_string(topology)=="honeycomb" or Atom.to_string(topology)=="randhoneycomb" do
      # # IO.puts(topology)
      # numNodes = BuildTopology.nearestPerfSquare(numNodes)
      # numNodes
      a=ceil(:math.pow(numNodes,0.33))
      cube = round(a*a*a)
      numNodes = cube
      numNodes
    else
      numNodes
    end
    # IO.puts(numNodes)
    numNodes = if Atom.to_string(topology)=="torus3D" do
      # numNodes = BuildTopology.nearestPerfSquare(numNodes)
      a=ceil(:math.pow(numNodes,0.33))
      cube = round(a*a*a)
      numNodes = cube
      numNodes
    else
      numNodes
    end
    nodeList = Enum.to_list(1..numNodes)
    table = :ets.new(:table, [:named_table, :public])
    adjList = Enum.map(1..numNodes,fn(x)->
      String.to_atom("node"<>Integer.to_string(x))
    end)
    :ets.insert_new(:table,{"nodes",adjList})
    # [headNode | _] = nodeList
    startPushSum(numNodes)

    start_time = (:erlang.system_time() / 1.0e6) |> round
    pushSumConvergence(nodeList, start_time)
  end

  def pushSumConvergence(node_list, startTime, acknowledgements \\ []) do
    receive do
      {:terminating, newSumEstimate, msg, pid} ->
        IO.puts(msg)
        numberOfNodes = length(node_list)

        acknowledgements = if !Enum.member?(acknowledgements, pid), do: acknowledgements ++ [pid]

        if length(acknowledgements) != numberOfNodes do
          pushSumConvergence(node_list, startTime, acknowledgements)
        else
          end_time = (:erlang.system_time() / 1.0e6) |> round
          # IO.puts("All nodes converged to the average value #{inspect(newSumEstimate)}")
          IO.puts("System converged in #{end_time - startTime} ms")
          Process.exit(self(), :kill)
          # System.halt(0)
        end
    end
    pushSumConvergence(node_list, startTime, acknowledgements)
  end


  def startGossip(numNodes,failNodes) do
    nodeList = Enum.to_list(1..numNodes)--failNodes
    startNode = numToName(Enum.random(nodeList))
    IO.puts("startNode #{startNode}")
    ActorNode.sendMessage(startNode,"I'm boo boo!",self())
    convergeCheck(0,length(nodeList))
  end


  def startPushSum(numNodes) do
    startNode = numToName(Enum.random(1..numNodes))
    # IO.puts "firstnode #{inspect firstnode}"
    ActorNode.pushSum(startNode,0,0,self())
    # convergeCheckPushSum(0,1)
  end


  def numToName(node) do
    String.to_atom("node"<>Integer.to_string(node))
  end


  def convergeCheck(n,numNodes) when n===numNodes do
    nil # n represents number of nodes knowing the rumor
  end


  def convergeCheck(n,numNodes) when n>=0 do
    receive do
      {:limitMessageReached,msg} ->
        IO.puts(msg)
        convergeCheck(n+1,numNodes)
        {:converged} -> IO.puts("converged")
    end
  end


  def convergeCheckPushSum(first,second) do
    receive do
      {:sum_estimate,cur} ->
        if isConverged(first,second,cur) do
          IO.puts "Converged! Sum estimate is #{cur}"
        else
          convergeCheckPushSum(second,cur)
        end
    end
  end

  def isConverged(first, second, third) do
      abs(first-second) <= :math.pow(10,-10) && abs(second-third) <= :math.pow(10,-10)
  end

end
