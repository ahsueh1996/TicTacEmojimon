pragma solidity >=0.8.0;
import { System } from "@latticexyz/world/src/System.sol";
import { Encounter, EncounterData, Encounterable, EncounterTrigger, MapConfig, Monster, Movable, Obstruction, Player, Position } from "../codegen/Tables.sol";
import { Player, Encounter, EncounterData, MonsterCatchAttempt, OwnedBy, Monster } from "../codegen/Tables.sol";
import { MonsterType } from "../codegen/Types.sol";
import { MonsterCatchResult } from "../codegen/Types.sol";
import { addressToEntityKey } from "../addressToEntityKey.sol";
import { positionToEntityKey } from "../positionToEntityKey.sol";

contract Mixing is System {

  enum M
  {
    x, y, spawn, flee
  }

  function F(uint32[] memory m) public {
    
    if (m[uint(M.spawn)]==1) {
      spawn(m[uint(M.x)], m[uint(M.y)]);
    }
  }

  function spawn(uint32 x, uint32 y) public {
    bytes32 player = addressToEntityKey(address(_msgSender()));
    require(!Player.get(player), "already spawned");
 
    // Constrain position to map size, wrapping around if necessary
    (uint32 width, uint32 height, ) = MapConfig.get();
    x = (x + width) % width;
    y = (y + height) % height;
 
    bytes32 position = positionToEntityKey(x, y);
    require(!Obstruction.get(position), "this space is obstructed");
 
    Player.set(player, true);
    Position.set(player, x, y);
    Movable.set(player, true);
    Encounterable.set(player, true);
  }
 
  function move(uint32 x, uint32 y) public {
    bytes32 player = addressToEntityKey(_msgSender());
    require(Movable.get(player), "cannot move");
 
    require(!Encounter.getExists(player), "cannot move during an encounter");
 
    (uint32 fromX, uint32 fromY) = Position.get(player);
    require(distance(fromX, fromY, x, y) == 1, "can only move to adjacent spaces");
 
    // Constrain position to map size, wrapping around if necessary
    (uint32 width, uint32 height, ) = MapConfig.get();
    x = (x + width) % width;
    y = (y + height) % height;
 
    bytes32 position = positionToEntityKey(x, y);
    require(!Obstruction.get(position), "this space is obstructed");
 
    Position.set(player, x, y);
 
    if (Encounterable.get(player) && EncounterTrigger.get(position)) {
      uint256 rand = uint256(keccak256(abi.encode(player, position, blockhash(block.number - 1), block.difficulty)));
      if (rand % 5 == 0) {
        startEncounter(player);
      }
    }
  }
 
  function distance(uint32 fromX, uint32 fromY, uint32 toX, uint32 toY) internal pure returns (uint32) {
    uint32 deltaX = fromX > toX ? fromX - toX : toX - fromX;
    uint32 deltaY = fromY > toY ? fromY - toY : toY - fromY;
    return deltaX + deltaY;
  }
 
  function startEncounter(bytes32 player) internal {
    bytes32 monster = keccak256(abi.encode(player, blockhash(block.number - 1), block.difficulty));
    MonsterType monsterType = MonsterType((uint256(monster) % uint256(type(MonsterType).max)) + 1);
    Monster.set(monster, monsterType);
    Encounter.set(player, EncounterData({ exists: true, monster: monster, catchAttempts: 0 }));
  }

    function throwBall() public {
    bytes32 player = addressToEntityKey(_msgSender());
 
    EncounterData memory encounter = Encounter.get(player);
    require(encounter.exists, "not in encounter");
 
    uint256 rand = uint256(
      keccak256(
        abi.encode(player, encounter.monster, encounter.catchAttempts, blockhash(block.number - 1), block.difficulty)
      )
    );
    if (rand % 2 == 0) {
      // 50% chance to catch monster
      MonsterCatchAttempt.emitEphemeral(player, MonsterCatchResult.Caught);
      OwnedBy.set(encounter.monster, player);
      Encounter.deleteRecord(player);
    } else if (encounter.catchAttempts >= 2) {
      // Missed 2 times, monster escapes
      MonsterCatchAttempt.emitEphemeral(player, MonsterCatchResult.Fled);
      Monster.deleteRecord(encounter.monster);
      Encounter.deleteRecord(player);
    } else {
      // Throw missed!
      MonsterCatchAttempt.emitEphemeral(player, MonsterCatchResult.Missed);
      Encounter.setCatchAttempts(player, encounter.catchAttempts + 1);
    }
  }
 
  function flee() public {
    bytes32 player = addressToEntityKey(_msgSender());
 
    EncounterData memory encounter = Encounter.get(player);
    require(encounter.exists, "not in encounter");
 
    Monster.deleteRecord(encounter.monster);
    Encounter.deleteRecord(player);
  }
}