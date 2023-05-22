// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import { System } from "@latticexyz/world/src/System.sol";
import { Player, Encounter, EncounterData, MonsterCatchAttempt, OwnedBy, Monster } from "../codegen/Tables.sol";
import { MonsterCatchResult } from "../codegen/Types.sol";
import { addressToEntityKey } from "../addressToEntityKey.sol";

import { System } from "@latticexyz/world/src/System.sol";
import { Encounter, EncounterData, Encounterable, EncounterTrigger, MapConfig, Monster, Movable, Obstruction, Player, Position } from "../codegen/Tables.sol";
import { MonsterType } from "../codegen/Types.sol";
import { addressToEntityKey } from "../addressToEntityKey.sol";
import { positionToEntityKey } from "../positionToEntityKey.sol";
import { F1 } from "./F1.sol";
import { F2 } from "./F2.sol";

contract F3System is System {
    enum M1 {
        x, y, spawn, flee, toss, move
    }
    
    enum M2 {
        x, y, spawn, put, move, reset
    }

    enum M3 {
        x, y, spawn, flee, toss, move
    }

    function F3(uint32[] memory input) public {
        // todo add new meta parameter for identifying which world is using this transition function
        uint32 x = input[uint(M3.x)];
        uint32 y = input[uint(M3.y)];
        uint32 spawn = input[uint(M3.spawn)];
        uint32 flee = input[uint(M3.flee)];
        uint32 toss = input[uint(M3.toss)];
        uint32 move = input[uint(M3.move)];

        bytes32 player = addressToEntityKey(_msgSender());

        require(Winner3.get()==bytes32(0),"There is a winner already!!");

        if (spawn==1) {
            //spawn in emojimon
            F1([x,y,1,0,0,0]);
        }
        if (flee==1){
            //exit encounter in emojimon and do not commit to put on TTT
            F1([0,0,0,1,0,0]);
        }
        if (toss==1){
            //throw ball in emojimon, if the capture is made, commit a put on TTT
            F1([0,0,0,0,1,0]);
            Encounter encounter = Encounter.get(player);
            MonsterCatchResult catchResult = MonsterCatchAttempt.get(addressToEntityKey(encounter));
            if (catchResult == MonsterCatchResult.Caught){            
                //check in TTT to see if there is a win for any player managing to make 3 in a row
                (uint32 x1, uint32 y1) = Position.get(player);
                // If I don't compute the information each time, I might be hard pressed thinking that i need to extend more states...
                //     // missing Where are TTT games located?
                // F2([x_,y_,0,1,0,0]);
                //     // missing who is represented by what marker
                // MarkerType = Winner.get();
                uint32 T21_x = x1-1;  // x2 + T21 = x1 frame transform
                uint32 T21_y = y1-1;
                F1([0,0,0,0,0,1]); // reset
                (uint32 w2, uint32 h2, )=MapConfig2.get();
                for (uint32 x2=0; x2<w2; x2++){
                    for (uint32 y2=0;y2<h2; y2++){
                        F2([x2,y2,0,0,1,0]); //move TTT, note we allowed teleport or this could have been messy... Alternatively, we can write directly to the S2 states
                        // something like this: Position2.set(player,x2,y2);
                        bytes32 qPos = positionToEntityKey(x2+T21_x, y2+T21_y);
                        //actually the states in emojimon do NOT save whether monsters occupy a grid. We cannot hijack the position nor terrain type either.
                        if (Map3.get(qPos).ownedBy == player){      // unfortunately it seems that it is more interesting to have mix games not as strict subsets.
                                                                    // if this game were a strict subset, I can only have 1 TTT game at a fixed position on game 1. which is fine as well.
                            MarkerType2 playerMarker = Marker.get(player);  // when storing states into the composite games, we may require direct writes to tables.
                            F1([0,0,0,1,0,0]);  //put
                            Marker2.set(player,playerMarkter);
                            if(Winner2.get()==playerMarker){
                                //what happens when you win?
                                Winner3.set(player);        
                            }
                        }
                    }
                }
            }
        }
        if (move==1) {
            //move in emojimon
            F1([x,y,0,0,0,1]); //move emojimon
        }
    }


}