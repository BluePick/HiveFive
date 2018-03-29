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
 This is the parent of Hive, QueenBee, Beetle, Grasshopper, Spider, and SoldierAnt, since all of them are pieces that together consist a hexagonal board.
 */
class HexNode {
    
    /**
           _____(up)_____
          /              \
     (upLeft)         (upRight)
        /     Oh Yeah!     \
        \      Hive        /
    (downLeft)       (downRight)
          \____(down)____/
     */
    struct SurroundingNodes {
        var up: HexNode?
        var upRight: HexNode?
        var upLeft: HexNode?
        var downRight: HexNode?
        var downLeft: HexNode?
        var down: HexNode?
    }
    
    var surroundings = SurroundingNodes()
    
}

extension HexNode.SurroundingNodes {
    
}