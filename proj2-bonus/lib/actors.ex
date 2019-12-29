defmodule ActorNode do
  use GenServer


  def start_link(nodename,nodenum) do
    GenServer.start_link(__MODULE__,["",0,nodenum,1,{},0,nodenum], name: nodename)
  end


  @impl true
  def init(state) do
    {:ok, state}
  end


  def updateAdjNodes(node,adjNodes) do
    GenServer.cast(node, {:updateAdjNodes, adjNodes})
  end


  @impl true
  def handle_cast({:updateAdjNodes,adjNodes},state) do
    {:noreply, List.replace_at(state,4,adjNodes)}
  end


  def getAdjList(node) do
    GenServer.call(node, :getAdjList)
  end


  @impl true
  def handle_call(:getAdjList,_from,state) do
    adjList = Enum.at(state,4)
    {:reply, adjList,state}
  end


  def sendMessage(node, message, parentpid) do
    GenServer.cast(node, {:sendMessage,message,parentpid})
  end


  @impl true
  def handle_cast({:sendMessage,message,parentpid}, state) do

    maxTimesMsg = 10
    childProcess = String.to_atom("node"<>Integer.to_string(Enum.at(state,6))<>"_child")
    if Process.whereis(childProcess) == nil && Enum.at(state,1) <= maxTimesMsg do
      # IO.puts "node child spawned: #{Enum.at(metadata,6)}"
      send parentpid, {:firstMessageReceived}
      adjNodes = Enum.at(state,4)
      # IO.inspect elem(Enum.at(:ets.lookup(:table, "failnodes"),0),1)
      adjNodes = adjNodes -- elem(Enum.at(:ets.lookup(:table, "failnodes"),0),1)
      # IO.inspect adjNodes
      child = spawn(ActorNode, :repeatSendMessage, [message, adjNodes, parentpid])
      Process.register(child, childProcess)
    end

    countMessagesHeard = Enum.at(state,1) + 1
    newstate = List.replace_at(state,0,message)
    newstate = List.replace_at(newstate,1,countMessagesHeard)

    if Process.whereis(childProcess)!=nil && countMessagesHeard >= maxTimesMsg  do
      Process.sleep(50)
      if Process.whereis(childProcess)!=nil && countMessagesHeard >= maxTimesMsg  do
        processName = String.to_atom("node"<>Integer.to_string(Enum.at(state,6)))
        send parentpid, {:limitMessageReached,"#{processName} converged and stopped transmitting"}
        try do
          Process.exit(Process.whereis(childProcess), :kill)
        rescue
          e in ArgumentError -> ""
        end
      #   IO.puts "node child terminated: #{Enum.at(state,6)}"
      end
    end
    {:noreply, newstate}
  end


  def repeatSendMessage(message,adjNodes, parentpid) do
    if length(adjNodes)!=0 do
    sendTo = Enum.random(adjNodes)
    # IO.inspect sendTo
    sendMessage(sendTo,message,parentpid)
    repeatSendMessage(message,adjNodes,parentpid)
    else
      # IO.puts("by")
      send parentpid, {:converged}
    end
  end


  def pushSum(node, s, w, parentpid) do
    GenServer.cast(node, {:pushSum, s, w, parentpid})
  end


  # @impl true
  # def handle_cast({:push_Sum,s,w,parentpid},state) do
  #   sOriginal = Enum.at(state,2)
  #   wOriginal = Enum.at(state,3)
  #   sNew = (Enum.at(state,2) + s)
  #   wNew = (Enum.at(state,3) + w)
  #   newstate = List.replace_at(state,2,sNew/2)
  #   newstate = List.replace_at(newstate,3,wNew/2)
  #   count = Enum.at(state,1)
  #   diff = abs((sNew/wNew) - (sOriginal/wOriginal))
  #   processName = String.to_atom("node"<>Integer.to_string(Enum.at(state,6)))
  #   IO.puts("#{sOriginal} #{wOriginal} #{sNew} #{wNew} #{s} #{w}")
  #   IO.puts(diff)
  #   if diff < :math.pow(10,-10) && count==2 do
  #     adjList = Enum.at(Tuple.to_list(Enum.at(:ets.lookup(:table, processName),0)),1)
  #     IO.inspect "HEllo"
  #     IO.inspect adjList
  #     # IO.puts(:ets.lookup(:table, x))
  #     Enum.each(adjList,fn(x)->
  #       eachAdjList = Enum.at(Tuple.to_list(Enum.at(:ets.lookup(:table, x),0)),1)
  #       eachAdjList = eachAdjList -- [processName]
  #       :ets.insert_new(:table,{x,eachAdjList})
  #       ActorNode.updateAdjNodes(x,eachAdjList)
  #       IO.inspect getAdjList(x)
  #       # Process.exit(Process.whereis(processName), :kill)
  #     end)
  #   end
  #   IO.inspect :ets.lookup(:table, :node1)
  #   count = if diff < :math.pow(10,-10) && count<2 do
  #     count = count + 1
  #   else
  #     count = 0
  #   end
  #   newstate = List.replace_at(newstate,1,count)
  #   newstate = List.replace_at(newstate,4,Enum.at(Tuple.to_list(Enum.at(:ets.lookup(:table, processName),0)),1))
  #   IO.inspect(newstate)
  #   # send parentpid,{:sum_estimate,sNew/wNew}
  #   # send half of its value out (new_s, new_w are already the halfed value)
  #   sendTo = Enum.random(Enum.at(newstate,4))
  #   pushSum(sendTo,sNew/2,wNew/2,parentpid)
  #   {:noreply,newstate}
  # end


  def handle_cast({:pushSum, sum, weight, parent}, state) do
    [_,counter, currentSum, currentWeight, neighbour_list,_,_] = state

    currentSumEstimate = currentSum / currentWeight

    newSum = currentSum + sum
    newWeight = currentWeight + weight
    newSumEstimate = newSum / newWeight

    difference = :math.pow(newSumEstimate - currentSumEstimate, 2) |> :math.sqrt()

    counter = if difference < :math.pow(10, -10), do: counter + 1, else: 0
    processName = String.to_atom("node"<>Integer.to_string(Enum.at(state,6)))
    # IO.inspect processName
    if counter == 3 do
      # IO.inspect state
      # IO.puts(counter)
      msg = "#{processName} converged and terminating...................................................."
      nodesList = elem(Enum.at(:ets.lookup(:table, "nodes"),0),1)
      nodesList = nodesList -- [processName]
      :ets.insert(:table,{"nodes",nodesList})
      # IO.puts("hello")
      # IO.inspect(length(elem(Enum.at(:ets.lookup(:table, "nodes"),0),1)))
      # IO.inspect(length(nodesList))
      # :ets.update_counter(:table, "nodes", nodesList)
      send parent, {:terminating, newSumEstimate, msg, self()}
      send self(), :kill
      # IO.puts("in this")

      Enum.each(neighbour_list,fn(x)->
        # IO.inspect length(neighbour_list)
        newAdjList = getAdjList(x) -- [processName]
        # IO.inspect x
        # IO.inspect newAdjList
        updateAdjNodes(x,newAdjList)
      end)
      Process.sleep(5)
      # IO.inspect (neighbour_list)
      if length(neighbour_list) != 0 do
        randomNode = Enum.random(neighbour_list)
        # IO.puts("randomnode one #{randomNode}")
        # IO.inspect Process.whereis(randomNode)
        ActorNode.pushSum(randomNode, newSum / 2, newWeight / 2, parent)
        # IO.puts("in this2")
      else
        nodesList = elem(Enum.at(:ets.lookup(:table, "nodes"),0),1)
        randomNode = Enum.random(nodesList)
        # IO.puts("in one #{randomNode}")
        ActorNode.pushSum(randomNode, 0, 0, parent)
      end
      # IO.inspect(length(elem(Enum.at(:ets.lookup(:table, "nodes"),0),1)))
    else
      # IO.puts("#{length(neighbour_list)} in teo")
      if length(neighbour_list) != 0 do

        randomNode = Enum.random(neighbour_list)
        # IO.inspect("otherrand two#{randomNode}")
        # IO.inspect processName
        # IO.inspect neighbour_list
        # IO.inspect Process.whereis(randomNode)
        ActorNode.pushSum(randomNode, newSum / 2, newWeight / 2, parent)
      else
        nodesList = elem(Enum.at(:ets.lookup(:table, "nodes"),0),1)
        randomNode = Enum.random(nodesList)
        # IO.puts("in two #{randomNode}")
        # IO.inspect Process.whereis(randomNode)
        ActorNode.pushSum(randomNode, 0, 0, parent)
      end

    end
    # IO.inspect("ejeijr")
    newstate = List.replace_at(state,1,counter)
    newstate = List.replace_at(newstate,2,newSum / 2)
    newstate = List.replace_at(newstate,3,newWeight / 2)
    newstate = List.replace_at(newstate,4,neighbour_list)
    # newState = {counter, newSum / 2, newWeight / 2, neighbour_list}

    {:noreply, newstate}
  end

  @impl true
  def handle_info(:kill, state) do
    {:stop, :normal, state}
  end


end


