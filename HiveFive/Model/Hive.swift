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
 The actual game has no boards, but we need an invisible board that is able to traverse/modify the HexNode ADT.
 */
class Hive {
    
    /**
     There should only be one instance of Hive throughout the application
     */
    static var sharedInstance: Hive = {
        return Hive()
    }()
    
    var root: HexNode? {
        didSet {
            //notify the delegate when the root changes
            delegate?.hiveDidUpdate()
        }
    }
    
    var blackHand: Hand
    var whiteHand: Hand
    var delegate: HiveDelegate?
    
    init() {
        blackHand = Hand()
        whiteHand = Hand()
    }
    
    /**
     - Returns: The furthest node in the given direction
     - Parameter from: Starting node
     - Parameter toward: The direction of trasversal propagation
     */
    static func traverse(from node: HexNode, toward dir: Direction) -> HexNode {
        var path = Path(route: Route(directions: []), destination: node)
        while path.destination.neighbors[.below] != nil {
            let dest = path.destination.neighbors[.below]!
            path = Path(route: path.route.append([.below]), destination: dest)
        }
        return path.destination
    }
    
}

protocol HiveDelegate {
    func hiveDidUpdate()
}

/**
 This struct is used to represent the available pieces at each player's disposal.
 */
struct Hand {
    var grasshoppers = 3
    var queenBees = 1
    var beetles = 2
    var spiders = 2
    var soldierAnts = 3
}

enum Insect: String {
    case grasshopper = "G", queenBee = "Q", beetle = "B", spider = "S", soldierAnt = "A"
}

protocol InsectProtocol {
    var insect: Insect {get}
}
