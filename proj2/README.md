Dos1
Group Members:
--------------
Chandan Chowdary (UFID-6972-9002) 
Gayathri Manogna Isireddy (UFID-9124-0699) 
The goal of this project is to implement Gossip Algorithm using Genserver in Elixir.

Project Hierarchy:
------------------
Please refer the project folder.

Instruction to run code:
------------------------
The following command is used to run the code:
./gossipex <<num.of.nodes>> <<topology>> <<algorithm>>

num.of.nodes is integer which is number of nodes
topology is one of the following
1)line
2)full
3)rand2D
4)honeycomb
5)randhoneycomb
6)3Dtorus

algorithm is one of the following
1)gossip
2)push-sum


The output displayed are the nodes that are converged and the time that was taken for all the nodes to converge.

What is working?
----------------
The logic that we have used is as follows:
In the beginning number of nodes, topology and algorithm is taken from the user through command line arguments. At first we build the topology which is one among the six topologies. Genserver is used to create actors and these actors are initiated with a state which has the message, count, s value, w value, adjacent nodes list and the number of that node. During the building of topology the adjacent nodes are calculated and are stored in the state. Once building of topology is done algorithm will start running which is either Gossip or Push-sum.

For Gossip:
A node is picked at random in the beginning and a message is sent to this node. This node listens the message and creates a child to transfer the node further to its adjacent nodes in regular intervals. In this way all the nodes are sent the message from its adjacent nodes and hence the convergence is achieved when all the nodes receives the message 10 times. If a node hears the message 10 times, it stops transmitting.

For Push-sum:
Push-sum is similar to gossip. When a node receives the s and w values, these values are added to the current s and w values of the node and half of each is kept at itself and half is sent to its adjacent nodes which is selected randomly. In this way if the difference in ratios of s and w values of a node doesn't change more than power(10,-10) then this node is terminated after sending the message to its adjacent node.

All the 6 topologies are implemented.

Line is implemented by calculating its adjacent nodes which are the one infront of it and the one that is its behind.

Full network's adjacent nodes are all other nodes except itself.

Random2D adjacent nodes are the calculated by placing the nodes randomly between the coordinates 0.0 and 1.0 on both the axis. Each node is assigned coordinates randomly and its neighbours are calculated by calculating the distance between two nodes and if its less than 0.1 it is a neighbour to the other.

Honeycomb nodes are arranged hexagonally. Its max degree is 3 and adjacent nodes of each node are calculated by using its position in the mesh.

Random honeycomb is arranged similar to the honeycomb except that a new connection is added into each node which is picked up randomly.

3D torus nodes are arranged in a torus grid in a 3D plane. When input nodes are given it is rounded to nearest perfect cube and the nodes are arranged in the grid. Each node has a degree 6 and are caluclated basing on the position of node in the grid.

What is the largest network you managed to deal with for each type of topology and algorithm?
----------------------------------------------------------------------------------------------
The largest network that we were able to manage is as follows:

For Gossip:

topology                          time(milli seconds)                   nodes
line                                  143611                            10000
full                                  30985                             10000
random2D                              76834                              5000
honeycomb                             4188                              10000
Random honeycomb                      3305                              10000
3D Torus                              1968                               5000

For Push-sum:

topology                          time(milli seconds)                   nodes
line                                  658243                            5000
full                                  627250                            10000
random2D                              120627                            5000
honeycomb                             120896                            10000
Random honeycomb                      143987                            10000
3D Torus                              113462                            10000

Results:
--------
Please refer project folder.


For the bonus part:
-------------------

Steps to run the application:

The following command is used to run the code:
./gossipex <<num.of.nodes>> <<failure_nodes>> <<topology>> <<algorithm>>

num.of.nodes is integer which is number of nodes
failure_nodes is number of failure nodes
topology is one of the following
1)line
2)full
3)rand2D
4)honeycomb
5)randhoneycomb
6)3Dtorus

Output is the time taken to achieve the convergence.

We have implemented the failure model for Gossip algorithm. In this model, we are killing the nodes after building the topology. This results in not sending of the message to those nodes. The final convergence of whole model is achieved when all the other nodes receive the message. There is least possibility that some nodes may not get converged. This occurs when there are no other nodes to send the message to that node.

We made changes so that it could accommadate the failure model. A registry is being used to always check what nodes are alive and before sending a message to that node it is checked in the registry if the node is alive. If the node is alive the message will pass on. Else the message will be sent to other nodes. If all the neighbour nodes are killed, the convergence cannot be achieved in all cases.

Parameter used:

This failure model is implemented basing on the number of failure nodes.
Please refer bonus_report.pdf for other information.

