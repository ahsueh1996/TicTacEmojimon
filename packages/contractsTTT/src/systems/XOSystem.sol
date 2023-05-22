// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import { System } from "@latticexyz/world/src/System.sol";
import { Player, Obstruction, OwnedBy, Marker, MapConfig} from "../codegen/Tables.sol";
import { MarkerType } from "../codegen/Types.sol";
import { addressToEntityKey } from "../addressToEntityKey.sol";
import { positionToEntityKey } from "../positionToEntityKey.sol";

contract XOSystem is System {

  function putMarker(uint32 x, uint32 y) public {
    bytes32 player = addressToEntityKey(_msgSender());
    bytes32 position = positionToEntityKey(x,y);    
    require(Obstruction.get(position)==MarkerType.None, "this space is obstructed");
    MarkerType playerMarker = Marker.get(player);
    Obstruction.set(position,playerMarker);
    OwnedBy.set(position,player);

    (uint32 width, uint32 height, bytes memory terrain) = MapConfig.get();
    terrain[(y * width) + x] = bytes1(uint8(playerMarker));

    MapConfig.set(width, height, terrain);
  }
}
