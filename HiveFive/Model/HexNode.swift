/**
 *
 *  This file is part of Hive Five.
 *
 *  Hive Five is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  Hive Five is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Hive Five.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

import Foundation

/**
 This is the parent of Hive, QueenBee, Beetle, Grasshopper, Spider, and SoldierAnt,
 since all of them are pieces that together consist a hexagonal board, a hexagonal node with
 references to all the neighbors is the ideal structure.
 */
protocol HexNode: AnyObject {
    var neighbors: Neighbors { get set }

    /**
     Derive the Path to every HexNode in the hive
     - Returns: The paths leading to the rest of the pieces in the hive
     */
    func derivePaths() -> [Path]

    /**
     - Returns: Whether taking this node up will break the structure.
     */
    func canDisconnect() -> Bool

    /**
     - Returns: Whe number of nodes that are connected to the current node, including the current node
     */
    func numConnected() -> Int

    /**
     - Returns: Whether the node has [other] as an immediate neighbor
     */
    func hasNeighbor(_ other: HexNode) -> Direction?

    /**
     - Returns: Whether the current node could move
     */
    func canMove() -> Bool

    /**
     Move the piece to the designated destination and **properly** connect the piece with the hive,
     i.e., handles multi-directional reference bindings, unlike connect(with:) which only handles bidirectional binding
     - Attention: this method assumes that the destination is a valid destination and that the route take is legal
     */
    func move(to destination: Destination)

    /**
     Moves the piece by following a certain route
     (just for convenience, because route is eventually resolved to a destination)
     */
    func move(by route: Route)

    /**
     Remove the reference to a specific node from its neighbors
     */
    func remove(_ node: HexNode)

    /**
     Returns self for convenient chained modification.
     - Parameter nodes: references to the nodes to be removed
     - Returns: self
     */
    func removeAll(_ nodes: [HexNode]) -> HexNode

    /**
     Connect bidirectionally with another node at a certain neighboring position.
     - Attention: Does not connect properly with the entire hive structure; only a bidirectional reference binding.
     - Parameter node: The node in which a bidirectional connection is to be established
     - Parameter dir: The direction in relation to the node to be connected with
     */
    func connect(with node: HexNode, at dir: Direction)

    /**
     When the node disconnects from the structure, all references to it from the neighbors should be removed.
     - Attention: Disconnect with all neighbors, i.e. remove from the hive
     */
    func disconnect()

    /**
     Disconnect with the specified node
     - Attention: Disconnect ONLY with the specified node, does not disconnect with all the surrounding nodes
     - Parameter node: The node with which the bidirectional connection is to be broken
     */
    func disconnect(with node: HexNode);

    /**
     The implementation for this method should be different for each class that conforms to the HexNode protocol.
     For example, a beetle's route may cover a piece while a Queen's route may never overlap another piece.
     - Returns: All possible locations in which the current node can arrive by following a defined route.
     */
    func availableMoves() -> [Route]

    /**
     - Returns: An array containing all the references to the connected pieces, including self; i.e. the entire hive
     */
    func connectedNodes() -> [HexNode]
    
    /**
     - Returns: Available moves within one step
     - Warning: This is a helper method for QueenBee::availableMoves, Beetle, and Spider, don't use it!
     */
    func oneStepMoves() -> [Route]
}

extension HexNode {

    func oneStepMoves() -> [Route] {
        return neighbors.available().map{($0.dir, $0.node.neighbors
                .adjacent(of: $0.dir.opposite())
                .filter{$0.node == nil}
                .map{$0.dir})}
                .map{(arg) -> [Route] in let (dir, dirs) = arg; return {
                    dirs.map{Route(directions: [dir, $0])}
                }()}
                .flatMap{$0}
    }

    func derivePaths() -> [Path] {
        var paths = [Path(route: Route(directions: []), destination: self)]
        derivePaths(&paths, paths[0].route) // the root path is initially []
        paths.removeFirst()
        return paths
    }

    /**
     - Parameter paths: Derived paths
     - Parameter root: The root path
     - Returns: Paths to the rest of the nodes in the hive from the current node
     */
    private func derivePaths(_ paths: inout [Path], _ root: Route) {
        let available = neighbors.available().filter {
            pair in !paths.contains(where: { pair.node === $0.destination })
        }
        
        if available.count == 0 {return} // base case
        let newPaths = available.map{Path(route: root.append([$0.dir]), $0.node)}
        paths.append(contentsOf: newPaths)
        newPaths.forEach{$0.destination.derivePaths(&paths, $0.route)} // recursive call
    }

    func canMove() -> Bool {
        return canDisconnect() && availableMoves().count > 0
    }

    func move(to destination: Destination) {
        self.disconnect() // disconnect from the hive
        let node = destination.node
        let dir = destination.dir
        connect(with: node, at: dir) // connect with destination node
        let pairs = Direction.allDirections.filter{$0 != dir.opposite()}
            .map{(dir: $0, trans: $0.translation())}
        // directions in which additional connections might need to be made
        
        derivePaths().map {path -> Destination? in //make additional connections to complete the hive
            let filtered = pairs.filter {path.route.translation == $0.trans}
            return filtered.count == 0 ? nil :
                Destination(node: path.destination, dir: filtered[0].dir)
            }.filter{$0 != nil}
            .map{$0!}
            .forEach{$0.node.connect(with: self, at: $0.dir)}
    }

    func move(by route: Route) {
        move(to: Destination.resolve(from: self, following: route))
    }

    func numConnected() -> Int {
        return connectedNodes().count
    }

    func connect(with node: HexNode, at dir: Direction) {
        assert(node.neighbors[dir] == nil)
        node.neighbors[dir] = self
        neighbors[dir.opposite()] = node
    }

    func canDisconnect() -> Bool {
        if self.neighbors[.above] != nil {return false} // little fucking beetle...
        let neighbors = self.neighbors // make a copy of the neighbors
        self.disconnect() // temporarily disconnect with all neighbors

        let available = neighbors.available() // extract all available neighbors
        let connected = available.map {$0.node.numConnected()}
        var canMove = true
        for i in (0..<(connected.count - 1)) {
            // if number of connected pieces are not the same for each piece after the current
            // node is removed from the structure, then the structure is broken.
            if connected[i] != connected[i + 1] {
                canMove = false
                break
            }
        }

        available.forEach {connect(with: $0.node, at: $0.dir.opposite())} // reconnect with neighbors
        return canMove
    }

    func disconnect() {
        neighbors.available().map {$0.node}.forEach {$0.disconnect(with: self)}
    }

    func disconnect(with node: HexNode) {
        assert(node.neighbors.contains(self) != nil) // make sure that the reference exist
        node.remove(self)
        assert(node.neighbors.contains(self) == nil) // make sure the reference is removed
        assert(neighbors.contains(node) != nil)
        remove(node)
        assert(neighbors.contains(node) == nil)
    }

    /**
     - Parameter pool: References to HexNodes that are already accounted for
     - Returns: An integer representing the number of nodes
     */
    private func deriveConnectedNodes(_ pool: inout [HexNode]) -> Int {
        let pairs = neighbors.available() // neighbors that are present
        if pool.contains(where: { $0 === self }) {return 0}
        pool.append(self) // add self to pool of accounted node such that it won't get counted again
        return pairs.map {$0.node}.filter { node in !pool.contains(where: { $0 === node })}
                .map {$0.deriveConnectedNodes(&pool)}
                .reduce(1) {$0 + $1}
    }

    func connectedNodes() -> [HexNode] {
        var pool = [HexNode]()
        let _ = deriveConnectedNodes(&pool)
        return pool
    }

    func remove(_ node: HexNode) {
        neighbors = neighbors.remove(node)
    }

    func removeAll(_ nodes: [HexNode]) -> HexNode {
        nodes.forEach(remove)
        return self
    }

    func hasNeighbor(_ other: HexNode) -> Direction? {
        return neighbors.contains(other)
    }
}
