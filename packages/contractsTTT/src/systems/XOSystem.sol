// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import { System } from "@latticexyz/world/src/System.sol";
import { Player, Obstruction, OwnedBy, Marker, MapConfig, Winner} from "../codegen/Tables.sol";
import { MarkerType } from "../codegen/Types.sol";
import { addressToEntityKey } from "../addressToEntityKey.sol";
import { positionToEntityKey } from "../positionToEntityKey.sol";

contract XOSystem is System {

  function putMarker(uint32 x, uint32 y) public {
    (MarkerType marker) = Winner.get();
    require(marker==MarkerType.None, "Winner has been determined");

    bytes32 player = addressToEntityKey(_msgSender());
    bytes32 position = positionToEntityKey(x,y);    
    require(Obstruction.get(position)==MarkerType.None, "this space is obstructed");
    MarkerType playerMarker = Marker.get(player);
    Obstruction.set(position,playerMarker);
    OwnedBy.set(position,player);

    (uint32 width, uint32 height, bytes memory terrain) = MapConfig.get();
    terrain[(y * width) + x] = bytes1(uint8(playerMarker));

    MapConfig.set(width, height, terrain);
    if (playerMarker == MarkerType.X){
      Marker.set(player, MarkerType.O);
    } else if (playerMarker == MarkerType.O){
      Marker.set(player, MarkerType.X);
    }

    checkWin();    
  }

  function reset() public {
    (uint32 width, uint32 height, ) = MapConfig.get();
    for (uint32 x=0; x<width; x++){
      for (uint32 y=0; y<height; y++){
        bytes32 position = positionToEntityKey(x,y);
        Obstruction.set(position,MarkerType.None);
        OwnedBy.deleteRecord(position);             
      }
    }    
    bytes memory terrain = new bytes(width * height);
    MapConfig.set(width, height, terrain);
    Winner.set(MarkerType.None);
  }

  function checkWin() internal {

    MarkerType tl;
    MarkerType tm;
    MarkerType tr;
    MarkerType cl;
    MarkerType cm;
    MarkerType cr;
    MarkerType bl;
    MarkerType bm;
    MarkerType br;
    cm = Obstruction.get(positionToEntityKey(1,1));
    tm = Obstruction.get(positionToEntityKey(1,0));
    tl = Obstruction.get(positionToEntityKey(0,0));
    cl = Obstruction.get(positionToEntityKey(0,1));
    br = Obstruction.get(positionToEntityKey(2,2));
    tr = Obstruction.get(positionToEntityKey(2,0));
    bl = Obstruction.get(positionToEntityKey(0,2));
    MarkerType winner = MarkerType.None;
    if (cm==tm || br==bl){      
      bm = Obstruction.get(positionToEntityKey(1,2));
      if ((cm==bm && cm==tm) || (br==bl && br==bm)){
        winner = bm;
      }        
    } else if (cm == cl || tr==br) {
      cr = Obstruction.get(positionToEntityKey(2,1));
      if ((cm==cr && cm==cl) || (cr==tr && tr==br)){
        winner = cr;
      }
    } else if (cm==tr && cm==bl){
      winner = cm;
    } else if (cm==br && cm==tl){
      winner = cm;
    } else if (tl==tm && tr==tm){
      winner = tm;
    } else if (tl==cl && cl==bl){
      winner = cl;
    }
    
    Winner.set(winner);

  }
}
