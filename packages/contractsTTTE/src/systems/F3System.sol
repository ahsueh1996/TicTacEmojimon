// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import { System } from "@latticexyz/world/src/System.sol";
import { Encounter1, Encounter1Data, Encounterable1, EncounterTrigger1, MapConfig1, MonsterCatchAttempt1, Monster1, Movable1, Obstruction1, OwnedBy1, Player1, Position1 } from "../codegen/Tables.sol";
import { MonsterCatchResult1, MonsterType1, TerrainType1 } from "../codegen/Types.sol";

import { MapConfig2, Marker2, Obstruction2, OwnedBy2, Player2, Winner2, Position2 } from "../codegen/Tables.sol";
import { MarkerType2, TerrainType2 } from "../codegen/Types.sol";

import { Map3, Winner3 } from "../codegen/Tables.sol";

import { addressToEntityKey } from "../addressToEntityKey.sol";
import { positionToEntityKey } from "../positionToEntityKey.sol";


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

    struct f3_slots {
        uint32 x;
        uint32 y;
        uint32 spawn;
        uint32 flee;
        uint32 toss;
        uint32 move;
        bytes32 player;
        uint32 o;
        bool winnerFound;
        MarkerType2 playerMarker;
        MarkerType2 winningMarker;
        bytes32 qPos;
    }

    function F3(uint32[] memory input) public {
        // todo add new meta parameter for identifying which world is using this transition function
        f3_slots memory f3;
        f3.x = input[uint(M3.x)];
        f3.y = input[uint(M3.y)];
        f3.spawn = input[uint(M3.spawn)];
        f3.flee = input[uint(M3.flee)];
        f3.toss = input[uint(M3.toss)];
        f3.move = input[uint(M3.move)];

        f3.player = addressToEntityKey(_msgSender());        
        require(Winner3.get()==bytes32(0),"There is a winner already!!");

        f3.o = 0;

        if (f3.spawn==1) {
            //spawn in emojimon
            F1([f3.x,f3.y,1,0,0,0]);
            F2([f3.o,0,1,0,0,0]);
        }
        if (f3.flee==1){
            //exit encounter in emojimon and do not commit to put on TTT
            F1([f3.o,0,0,1,0,0]);
        }
        if (f3.toss==1){
          //throw ball in emojimon, if the capture is made, commit a put on TTT
          Encounter1Data memory encounter = Encounter1.get(f3.player);
          // require(encounter.exists, "check from F3 not in encounter");
          // MonsterCatchResult1 catchResult = MonsterCatchAttempt1.get(player); // This is an ephemeral pattern! so I can't do this
          //MonsterCatchResult1 catchResult = F1([z,0,0,0,1,0]);        // must extend to have return value.. >>> <<<< this means it's just doesn't work well with this composing protocol
          MonsterCatchResult1 catchResult = _throwBall(); // F1 signature is not meant to return anything. 
          if (catchResult == MonsterCatchResult1.Caught){
            Encounter1.deleteRecord(f3.player);                            
            //check in TTT to see if there is a win for any player managing to make 3 in a row
            (uint32 x1, uint32 y1) = Position1.get(f3.player);
            Map3.set(positionToEntityKey(x1,y1), Monster1.get(encounter.monster), f3.player);
            // If I don't compute the information each time, I might be hard pressed thinking that i need to extend more states...
            //     // missing Where are TTT games located?
            // F2([x_,y_,0,1,0,0]);
            //     // missing who is represented by what marker             
            (uint32 w2, uint32 h2, )=MapConfig2.get();
            f3.winnerFound = false;
            for (uint32 cx=0; cx<w2; cx++){
                for (uint32 cy=0;cy<h2; cy++){
                  uint32 T21_x = x1-cx;  // x2 + T21 = x1 frame transform
                  uint32 T21_y = y1-cy;
                  F2([f3.o,0,0,0,0,1]); // reset TTT
                  // _reset2();
                  for (uint32 x2=0; x2<w2; x2++){
                    for (uint32 y2=0;y2<h2; y2++){
                      //F2([x2,y2,0,0,1,0]); //move TTT, note we allowed teleport or this could have been messy... Alternatively, we can write directly to the S2 states
                      Position2.set(f3.player, x2, y2);        // we end up with this because of call stack too deep issue
                      f3.qPos = positionToEntityKey(x2+T21_x, y2+T21_y);
                      //actually the states in emojimon do NOT save whether monsters occupy a grid. We cannot hijack the position nor terrain type either.
                      (, bytes32 ownerPlayer) = Map3.get(f3.qPos);
                      if (ownerPlayer == f3.player){      // unfortunately it seems that it is more interesting to have mix games not as strict subsets.
                                                                  // if this game were a strict subset, I can only have 1 TTT game at a fixed position on game 1. which is fine as well.
                          f3.playerMarker = Marker2.get(f3.player);  // when storing states into the composite games, we may require direct writes to tables.
                          // F2([f3.o,0,0,1,0,0]);  //put
                          _putMarker2(x2,y2); // choose this because of stack too deep..
                          Marker2.set(f3.player,f3.playerMarker);
                          f3.winningMarker = Winner2.get();
                          if(f3.winningMarker==f3.playerMarker && f3.winningMarker != MarkerType2.None){
                              //what happens when you win?
                              Winner3.set(f3.player);
                              f3.winnerFound = true;
                              break;                                        
                          }
                      }
                      if (f3.winnerFound) { break;}                            
                    }
                    if (f3.winnerFound) { break;}
                  }
                  if (f3.winnerFound) { break;}
                }
                if (f3.winnerFound) { break;}
            }
          }
            
        }
        if (f3.move==1) {
            //move in emojimon
            F1([f3.x,f3.y,0,0,0,1]); //move emojimon
        }
    }

    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        uint8 i = 0;
        bytes memory bytesArray = new bytes(64);
        for (i = 0; i < bytesArray.length; i++) {

            uint8 _f = uint8(_bytes32[i/2] & 0x0f);
            uint8 _l = uint8(_bytes32[i/2] >> 4);

            bytesArray[i] = toByte(_f);
            i = i + 1;
            bytesArray[i] = toByte(_l);
        }
        return string(bytesArray);
    }

    function toByte(uint8 _uint8) internal pure returns (bytes1) {
        if(_uint8 < 10) {
            return bytes1(_uint8 + 48);
        } else {
            return bytes1(_uint8 + 87);
        }
    }

    function toAsciiString(address x) internal pure returns (string memory) {
    bytes memory s = new bytes(40);
    for (uint i = 0; i < 20; i++) {
        bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
        bytes1 hi = bytes1(uint8(b) / 16);
        bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
        s[2*i] = char(hi);
        s[2*i+1] = char(lo);            
    }
    return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }






    function F1(uint32[6] memory input) internal {
        // todo add new meta parameter for identifying which world is using this transition function
        uint32 x = input[uint(M1.x)];
        uint32 y = input[uint(M1.y)];
        uint32 spawn = input[uint(M1.spawn)];
        uint32 flee = input[uint(M1.flee)];
        uint32 toss = input[uint(M1.toss)];
        uint32 move = input[uint(M1.move)];

        if (spawn==1) {
            _spawn(x, y);
        }
        if (flee==1){
            _flee();
        }
        if (toss==1){
            _throwBall();
        }
        if (move==1) {
            _move(x, y);
        }
    }

    function _throwBall() internal returns (MonsterCatchResult1) {
    bytes32 player = addressToEntityKey(_msgSender());

    Encounter1Data memory encounter = Encounter1.get(player);
    require(encounter.exists, "not in encounter");

    uint256 rand = uint256(keccak256(abi.encode(player, encounter.monster, encounter.catchAttempts, blockhash(block.number - 1), block.difficulty)));
    if (rand % 10 != 0) {
        // 90% chance to catch monster
        MonsterCatchAttempt1.emitEphemeral(player, MonsterCatchResult1.Caught);
        OwnedBy1.set(encounter.monster, player);
        Encounter1.deleteRecord(player);
        return MonsterCatchResult1.Caught;
    } else if (encounter.catchAttempts >= 2) {
        // Missed 2 times, monster escapes
        MonsterCatchAttempt1.emitEphemeral(player, MonsterCatchResult1.Fled);
        Monster1.deleteRecord(encounter.monster);
        Encounter1.deleteRecord(player);
        return MonsterCatchResult1.Fled;
    } else {
        // Throw missed!
        MonsterCatchAttempt1.emitEphemeral(player, MonsterCatchResult1.Missed);
        Encounter1.setCatchAttempts(player, encounter.catchAttempts + 1);
        return MonsterCatchResult1.Missed;
    }
    }

    function _flee() internal {
    bytes32 player = addressToEntityKey(_msgSender());

    Encounter1Data memory encounter = Encounter1.get(player);
    require(encounter.exists, "not in encounter");

    Monster1.deleteRecord(encounter.monster);
    Encounter1.deleteRecord(player);
    }

    function _spawn(uint32 x, uint32 y) internal {
    bytes32 player = addressToEntityKey(address(_msgSender()));
    require(!Player1.get(player), "already spawned");

    // Constrain position to map size, wrapping around if necessary
    (uint32 width, uint32 height, ) = MapConfig1.get();
    x = (x + width) % width;
    y = (y + height) % height;

    bytes32 position = positionToEntityKey(x, y);
    require(!Obstruction1.get(position), "this space is obstructed");

    Player1.set(player, true);
    Position1.set(player, x, y);
    Movable1.set(player, true);
    Encounterable1.set(player, true);
    }

    function _move(uint32 x, uint32 y) internal {
    bytes32 player = addressToEntityKey(_msgSender());
    require(Movable1.get(player), "cannot move");

    require(!Encounter1.getExists(player), "cannot move during an encounter");

    (uint32 fromX, uint32 fromY) = Position1.get(player);
    // require(_distance(fromX, fromY, x, y) == 1, "can only move to adjacent spaces");

    // Constrain position to map size, wrapping around if necessary
    (uint32 width, uint32 height, ) = MapConfig1.get();
    x = (x + width) % width;
    y = (y + height) % height;

    bytes32 position = positionToEntityKey(x, y);
    require(!Obstruction1.get(position), "this space is obstructed");

    Position1.set(player, x, y);

    // require(false, toAsciiString(_msgSender()));

    if (Encounterable1.get(player) && EncounterTrigger1.get(position)) {
        uint256 rand = uint256(keccak256(abi.encode(player, position, blockhash(block.number - 1), block.difficulty)));
        if (rand % 10 != 0) {
        _startEncounter(player);
        }
    }
    }

    function _distance(uint32 fromX, uint32 fromY, uint32 toX, uint32 toY) internal pure returns (uint32) {
    uint32 deltaX = fromX > toX ? fromX - toX : toX - fromX;
    uint32 deltaY = fromY > toY ? fromY - toY : toY - fromY;
    return deltaX + deltaY;
    }

    function _startEncounter(bytes32 player) internal {
    bytes32 monster = keccak256(abi.encode(player, blockhash(block.number - 1), block.difficulty));
    MonsterType1 monsterType = MonsterType1((uint256(monster) % uint256(type(MonsterType1).max)) + 1);
    Monster1.set(monster, monsterType);
    Encounter1.set(player, Encounter1Data({exists: true, monster: monster, catchAttempts: 0}));
    }
















    function F2(uint32[6] memory input) internal {
        // todo add new meta parameter for identifying which world is using this transition function
        uint32 x = input[uint(M2.x)];
        uint32 y = input[uint(M2.y)];
        uint32 spawn = input[uint(M2.spawn)];
        uint32 put = input[uint(M2.put)];
        uint32 move = input[uint(M2.move)];        
        uint32 reset = input[uint(M2.reset)];

        if (spawn==1) {
            _spawn2(x, y);
        }
        if (put==1){
            _putMarker2(x, y);
        }
        if (move==1) {
            _move2(x, y);
        }
        if (reset==1) {
            _reset2();
        }
    }

  function _spawn2(uint32 x, uint32 y) internal {
    bytes32 player = addressToEntityKey(address(_msgSender()));
    require(!Player2.get(player), "already spawned");

    // Constrain position to map size, wrapping around if necessary
    (uint32 width, uint32 height, ) = MapConfig2.get();
    x = (x + width) % width;
    y = (y + height) % height;

    Player2.set(player, true);
    Position2.set(player, x, y);
    Marker2.set(player,MarkerType2.X); // start with X
  }

  function _move2(uint32 x, uint32 y) internal {
    bytes32 player = addressToEntityKey(_msgSender());

    (uint32 fromX, uint32 fromY) = Position2.get(player);

    // Constrain position to map size, wrapping around if necessary
    (uint32 width, uint32 height, ) = MapConfig2.get();
    x = (x + width) % width;
    y = (y + height) % height;

    Position2.set(player, x, y);
  }

  function _distance2(uint32 fromX, uint32 fromY, uint32 toX, uint32 toY) internal pure returns (uint32) {
    uint32 deltaX = fromX > toX ? fromX - toX : toX - fromX;
    uint32 deltaY = fromY > toY ? fromY - toY : toY - fromY;
    return deltaX + deltaY;
  }

  function _putMarker2(uint32 x, uint32 y) internal {
    (MarkerType2 winningMarker) = Winner2.get();
    require(winningMarker==MarkerType2.None, "Winner2 has been determined");

    bytes32 player = addressToEntityKey(_msgSender());
    bytes32 position = positionToEntityKey(x,y);    
    require(Obstruction2.get(position)==MarkerType2.None, "this space is obstructed");
    MarkerType2 playerMarker = Marker2.get(player);
    Obstruction2.set(position,playerMarker);
    OwnedBy2.set(position,player);

    (uint32 width, uint32 height, bytes memory terrain) = MapConfig2.get();
    terrain[(y * width) + x] = bytes1(uint8(playerMarker));

    MapConfig2.set(width, height, terrain);
    if (playerMarker == MarkerType2.X){
      Marker2.set(player, MarkerType2.O);
    } else if (playerMarker == MarkerType2.O){
      Marker2.set(player, MarkerType2.X);
    }

    _checkWin2();    
  }

  function _reset2() internal {
    (uint32 width, uint32 height, ) = MapConfig2.get();
    for (uint32 x=0; x<width; x++){
      for (uint32 y=0; y<height; y++){
        bytes32 position = positionToEntityKey(x,y);
        Obstruction2.set(position,MarkerType2.None);
        OwnedBy2.deleteRecord(position);             
      }
    }    
    bytes memory terrain = new bytes(width * height);
    MapConfig2.set(width, height, terrain);
    Winner2.set(MarkerType2.None);
  }

  function _checkWin2() internal {

    MarkerType2 tl;
    MarkerType2 tm;
    MarkerType2 tr;
    MarkerType2 cl;
    MarkerType2 cm;
    MarkerType2 cr;
    MarkerType2 bl;
    MarkerType2 bm;
    MarkerType2 br;
    cm = Obstruction2.get(positionToEntityKey(1,1));
    tm = Obstruction2.get(positionToEntityKey(1,0));
    tl = Obstruction2.get(positionToEntityKey(0,0));
    cl = Obstruction2.get(positionToEntityKey(0,1));
    br = Obstruction2.get(positionToEntityKey(2,2));
    tr = Obstruction2.get(positionToEntityKey(2,0));
    bl = Obstruction2.get(positionToEntityKey(0,2));
    MarkerType2 winner = MarkerType2.None;
    if (cm==tm || br==bl){      
      bm = Obstruction2.get(positionToEntityKey(1,2));
      if ((cm==bm && cm==tm) || (br==bl && br==bm)){
        winner = bm;
      }        
    } else if (cm == cl || tr==br) {
      cr = Obstruction2.get(positionToEntityKey(2,1));
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
    
    Winner2.set(winner);

  }
}