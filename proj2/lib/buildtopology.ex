defmodule BuildTopology do

  def getTopology(numNodes, algorithm, :line) do
      buildNodes(numNodes)
      updateAdjNodesLine(numNodes)
  end


  def getTopology(numNodes, algorithm,  :full) do
      buildNodes(numNodes)
      updateAdjNodesFull(numNodes)
  end


  def getTopology(numNodes, algorithm,  :rand2D) do
    buildNodes(numNodes)
    updateAdjNodesRand2D(numNodes)
  end


  def getTopology(numNodes,  algorithm, :torus3D) do
    a=ceil(:math.pow(numNodes,0.33))
    cube = round(a*a*a)
    buildNodes(cube)
    adjList = updateAdjNodes3DTorus(numNodes)
    adjList
  end


  def getTopology(numNodes, algorithm,  :honeycomb) do
    if Atom.to_string(algorithm)=="pushsum" do
      getTopology(numNodes, algorithm,  :honeycombpushsum)
    else
      adjList = updateAdjNodesHoneyComb(numNodes)
      numNodes = nearestPerfSquare(numNodes)
      buildNodes(numNodes)
      Enum.each(0..numNodes-1,fn(x)->
        # IO.inspect Enum.at(adjList,x)
        adjNodes = Enum.map(Enum.at(adjList,x),fn(y)->
          String.to_atom("node"<>Integer.to_string(y))
        end)
        # IO.puts(x+1)
        # IO.inspect(adjNodes)
        ActorNode.updateAdjNodes(String.to_atom("node"<>Integer.to_string(x+1)),adjNodes)
      end)
    end
  end

  def getTopology(numNodes, algorithm,  :honeycombpushsum) do
    a=ceil(:math.pow(numNodes,0.33))
    cube = round(a*a*a)
    buildNodes(cube)
    adjList = updateAdjNodes3DTorus(numNodes)
    adjList
  end


  def getTopology(numNodes, algorithm,  :randhoneycomb) do
    if Atom.to_string(algorithm)=="pushsum" do
      getTopology(numNodes, algorithm,  :randhoneycombpushsum)
    else
    adjList = updateAdjNodesRandHoneyComb(numNodes)
    # IO.inspect length(adjList)
    numNodes = nearestPerfSquare(numNodes)
    buildNodes(numNodes)
    # IO.inspect numNodes
    Enum.each(0..numNodes-1,fn(x)->
      # IO.inspect Enum.at(adjList,x)
      adjNodes = Enum.map(Enum.at(adjList,x),fn(y)->
        String.to_atom("node"<>Integer.to_string(y))
      end)
      ActorNode.updateAdjNodes(String.to_atom("node"<>Integer.to_string(x+1)),adjNodes)
    end)
  end
  end


  def getTopology(numNodes, algorithm,  :randhoneycombpushsum) do
    a=ceil(:math.pow(numNodes,0.33))
    cube = round(a*a*a)
    buildNodes(cube)
    adjList = updateAdjNodes3DTorus(numNodes)
    adjList
  end


  def buildNodes(numNodes) do
    Enum.each(1..numNodes,fn(x)->
      nodeName = String.to_atom("node"<>Integer.to_string(x))
      ActorNode.start_link(nodeName,x)
    end)
  end


  def updateAdjNodesLine(numNodes) do
    endNode = numNodes
    # IO.puts(endNode)
    Enum.each(1..numNodes,fn(x)->
      adjNodes = cond do
        x==1       -> [x+1]
        x==endNode -> [numNodes-1]
        true       -> [x-1,x+1]
      end
      # IO.inspect adjNodes
      adjNodes = Enum.map(adjNodes,fn(x)->
        String.to_atom("node"<>Integer.to_string(x))
      end)
      # IO.inspect adjNodes
      ActorNode.updateAdjNodes(String.to_atom("node"<>Integer.to_string(x)),adjNodes)
    end)
  end


  def updateAdjNodesFull(numNodes) do
    nodes = Enum.to_list(1..numNodes)
    Enum.each(nodes,fn(x)->
      adjNodes = nodes -- [x]
      adjNodes = Enum.map(adjNodes,fn(x)->
        String.to_atom("node"<>Integer.to_string(x))
      end)
      # IO.puts(x)
      ActorNode.updateAdjNodes(String.to_atom("node"<>Integer.to_string(x)),adjNodes)
    end)
  end


  def updateAdjNodesRand2D(numNodes) do
    x = [0]
    temp = 0
    x = generateNodesRand2D(numNodes, temp, x)
    x = x -- [Enum.at(x,length(x)-1)]
    y = x
    list = Enum.to_list(1..numNodes)
    x = Enum.shuffle(x)
    y = Enum.shuffle(y)
    nodesList = Enum.map(0..numNodes-1,fn(tmp)->
      [Enum.at(x,tmp),Enum.at(y,tmp)]
    end)
    Enum.each(list,fn(x)->
      currentCoord = Enum.at(nodesList,x-1)
      adjNodes = Enum.map(nodesList,fn(y)->
        x1 = Enum.at(currentCoord,0)
        y1 = Enum.at(currentCoord,1)
        x2 = Enum.at(y,0)
        y2 = Enum.at(y,1)
        diff1 = abs(x1-x2)
        diff2 = abs(y1-y2)
        diff = diff1+diff2
        node = if diff <= 0.5 and diff1 != 0 do
          index = Enum.find_index(nodesList, fn x -> x == y end)
          String.to_atom("node"<>Integer.to_string(index+1))
        else
          []
        end
        node
      end)
      adjNodes = List.flatten(adjNodes) -- [[]]
      # IO.inspect(adjNodes)
      ActorNode.updateAdjNodes(String.to_atom("node"<>Integer.to_string(x)),adjNodes)
    end)
  end


  def generateNodesRand2D(numNodes, temp, list) when temp >= 1.0 do
    temp = temp + 1.0/numNodes
    list = list ++ [temp]
    list
  end


  def generateNodesRand2D(numNodes, temp, list) do
    temp = temp + 1.0/numNodes
    list = list ++ [temp]
    list = generateNodesRand2D(numNodes, temp, list)
    list
  end


  def updateAdjNodesHoneyComb(numNodes) do
    numNodes = nearestPerfSquare(numNodes)
    rows = round(:math.sqrt(numNodes))
    firstRow = Enum.to_list(1..rows)
    lastRow = Enum.to_list(((rows*rows)-rows+1)..rows*rows)
    firstRow = Enum.map(firstRow,fn(x)->
      adjNodes = cond do
        x==1    -> [x+1,x+rows]
        x==rows -> if rem(x,2) == 0 do
                      [x-1]
                    else
                      [x-1,x+rows]
                    end
        true    ->  if rem(x,2) == 0 do
                      [x-1,x+1]
                    else
                      [x-1,x+1,x+rows]
                    end
      end
      adjNodes
    end)
    middleRows = Enum.to_list(rows+1..((rows*rows)-rows))
    middleRows = Enum.map(middleRows,fn(x)->
      rowOfNode = round(ceil(x/rows))
      adjNodes = cond do
        rem(x,rows)==1    ->if rem(rowOfNode,2)==0 do
                              [x-rows,x+1]
                            else
                              [x+1,x+rows]
                            end
        rem(x,rows)==0    -> cond do
          rem(rows,2)!=0 -> if rem(rowOfNode,2)==0 do
                              [x-rows,x-1]
                            else
                              [x-1,x+rows]
                            end
          true            -> if rem(rowOfNode,2)!=0 do
                              [x-rows,x-1]
                            else
                              [x-1,x+rows]
                            end
                          end
        rem(rows,2)==1    ->  cond do
          rem(rowOfNode,2)==0 -> if rem(x,2) != 0 do
                                  [x-1,x+1,x+rows]
                                else
                                  [x-rows,x-1,x+1]
                                end
          true                -> if rem(x,2) == 0 do
                                  [x-1,x+1,x+rows]
                                else
                                  [x-rows,x-1,x+1]
                                end
        end
        true    ->  cond do
          rem(rowOfNode,2)==0 -> if rem(x,2) == 0 do
                                  [x-1,x+1,x+rows]
                                else
                                  [x-rows,x-1,x+1]
                                end
          true                -> if rem(x,2) != 0 do
                                  [x-1,x+1,x+rows]
                                else
                                  [x-rows,x-1,x+1]
                                end
        end


      end
      adjNodes
    end)
    lastRow = Enum.map(lastRow,fn(x)->
      adjNodes = cond do
        x==((rows*rows)-rows+1)    -> if rem(rows,2) == 0 do
                                        [x-rows,x+1]
                                      else
                                        [x+1]
                                      end
        x==rows*rows -> [x-1]
        rem(x,2)==0    ->  if rem(rows,2) == 0 do
                      [x-1,x+1]
                    else
                      [x-1,x+1,x-rows]
                    end
        true         ->   if rem(rows,2) == 0 do
                            [x-1,x+1,x-rows]
                          else
                            [x-1,x+1]
                          end
      end
      adjNodes
    end)
    # IO.inspect(firstRow)
    # IO.inspect(middleRows)
    # IO.inspect(lastRow)
    adjList = firstRow ++ middleRows ++ lastRow
    adjList
  end


  def nearestPerfSquare(a) do
    if(:math.sqrt(a) == round(:math.sqrt(a))) do
        a
    else
        i=round(:math.ceil(:math.sqrt(a)))
        i*i
    end
  end


  def updateAdjNodesRandHoneyComb(numNodes) do
    adjList = updateAdjNodesHoneyComb(numNodes)
    numNodes = nearestPerfSquare(numNodes)
    # nodesList = Enum.to_list(1..numNodes)
    newAdjList1 = Enum.map(1..round(numNodes/2),fn(x)->
      adj = Enum.at(adjList,x-1)
      adj = adj ++ [x+round(numNodes/2)]
      adj
    end)
    newAdjList2 = Enum.map(round(numNodes/2)+1..numNodes,fn(x)->
      adj = Enum.at(adjList,x-1)
      adj = adj ++ [x-round(numNodes/2)]
      adj
    end)
    newAdjList = newAdjList1 ++ newAdjList2
    # IO.inspect newAdjList
    newAdjList
  end


  def updateAdjNodes3DTorus(numNodes) do
    a=ceil(:math.pow(numNodes,0.33))
    cube = round(a*a*a)
    numNodes = cube
    adjList = Enum.map(1..numNodes,fn(x)->
      a=ceil(:math.pow(numNodes,0.33))
      # IO.inspect a
      y=ceil(x/(a*a))
      # IO.inspect x

      adj=cond do
        y==1 -> firstPlane(x,a)
        y==a -> lastPlane(x,a)
        true -> middlePlanes(x,y,a)
    end
      # IO.inspect  adj, charlists: :as_lists
      adjNodes = Enum.map(adj,fn(node)->
        String.to_atom("node"<>Integer.to_string(node))
      end)
      ActorNode.updateAdjNodes(String.to_atom("node"<>Integer.to_string(x)),adjNodes)
    end)
    adjList
  end

  def firstPlane(x,a) do

    adj=cond do
      x==1 -> [2,a+1,a,a*a+1,a*a-a+1,(a-1)*a*a+1]
      x==a -> [a-1,2*a,a*a+a,a*a,1,(a-1)*a*a+x]
      x==(a*a-a+1)->[1,a*a-a+2,a*a-2*a+1,2*a*a-a+1,a*a,a*a*a-a+1]
      x==(a*a) -> [a*a-1,a*a-a,2*a*a,a,a*a*a,a*a-a+1]
      rem(x,a)==0 ->[x-1,x-a,x+a,x+a*a,x-a+1,(a-1)*a*a+x]
      rem(x,a)==1 ->[x+1,x-a,x+a,a*a+x,x+a-1,(a-1)*a*a+x]
      x>1 and x<a ->[x-1,x+1,x+a,x+a*a,x+(a-1)*a,(a-1)*a*a+x]
      x>a*a-a+1 and x<a*a ->[x-1,x+1,x-a,x-(a-1)*a,a*a+x,(a-1)*a*a+x]
      true -> [x-1,x+1,x-a,x+a,x+a*a,x+(a-1)*a*a]
    end
    adj
  end


  def lastPlane(x,a) do
    adj=cond do
      x==(a-1)*a*a+1 ->[(a-1)*a*a+2,(a-1)*a*a+1+a,(a-1)*a*a+1-a*a,(a-1)*a*a+a,1,a*a*a-a+1]
      x==(a-1)*a*a+a -> [(a-1)*a*a+a-1,(a-1)*a*a+a+a,(a-1)*a*a+a-a*a,a*a*a,(a-1)*a*a+1,a]
      x==a*a*a-a+1 -> [a*a*a-a+2,a*a*a-a+1-a,a*a*a-a+1-a*a,(a-1)*a*a+1,a*a*a,a*a-a+1]
      x==a*a*a -> [a*a*a-1,a*a*a-a*a,a*a*a-a,a*a,(a-1)*a*a+a,a*a*a-a+1]
      rem(x,a)==0 -> [x-1,x+a,x-a,x-a*a,x-a+1,x-(a-1)*a*a]
      rem(x,a)==1 -> [x+1,x-a,x+a,x-a*a,x+a-1,x-(a-1)*a*a]
      x>(a-1)*a*a+1 and x<(a-1)*a*a+a ->[x+1,x-1,x+a,x-a*a,x-(a-1)*a*a,x+(a-1)*a]
      x>a*a*a-a+1 and x<a*a*a -> [x+1,x-1,x-a,x-a*a,x-(a-1)*a*a,x-(a-1)*a]
      true ->  [x+1,x-1,x+a,x-a,x-a*a,x-(a-1)*a*a]
    end
    adj
  end

def middlePlanes(x,y,a) do
  adj = cond do
    x==(y-1)*a*a+1 ->[x+1,x+a,x-a*a,x+a*a,y*a*a-a+1,(y-1)*a*a+a]
    x==(y-1)*a*a+a ->[x-1,x+a,x+a*a,x-a*a,(y-1)*a*a+1,y*a*a]
    x==y*a*a-a+1 ->[x+1,x-a,x+a*a,x-a*a,(y-1)*a*a+1,y*a*a]
    x==y*a*a -> [x-1,x-a,x+a*a,x-a*a,y*a*a-a+1,(y-1)*a*a+a]
    rem(x,a)==0 ->[x-1,x+a,x-a,x+a*a,x-a*a,x-a+1]
    rem(x,a)==1 -> [x+1,x-a,x+a,x+a*a,x-a*a,x+a-1]
    x>(y-1)*a*a+1 and x<(y-1)*a*a+a -> [x+1,x-1,x+a,x-a*a,x+a*a,x+(a-1)*a]
    x>y*a*a-a+1 and x<y*a*a -> [x+1,x-1,x-a,x-a*a,x+a*a,x-(a-1)*a]
    true ->[x+1,x-1,x+a,x-a,x+a*a,x-a*a]

  end
  adj

end

end

# BuildTopology.updateAdjNodes3DTorus(1000)
