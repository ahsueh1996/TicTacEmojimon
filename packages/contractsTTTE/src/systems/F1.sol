// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import { System } from "@latticexyz/world/src/System.sol";
import { Player1, Encounter1, EncounterData1, MonsterCatchAttempt1, OwnedBy1, Monster1 } from "../codegen/Tables.sol";
import { MonsterCatchResult } from "../codegen/Types.sol";
import { addressToEntityKey } from "../addressToEntityKey.sol";

import { System } from "@latticexyz/world/src/System.sol";
import { Encounter1, EncounterData1, Encounterable1, EncounterTrigger1, MapConfig1, Monster1, Movable1, Obstruction1, Player1, Position1 } from "../codegen/Tables.sol";
import { MonsterType1 } from "../codegen/Types.sol";
import { addressToEntityKey } from "../addressToEntityKey.sol";
import { positionToEntityKey } from "../positionToEntityKey.sol";

//contract F1System is System {
    enum M {
        x, y, spawn, flee, toss, move
    }
    function F1(uint32[] memory input) internal {
        // todo add new meta parameter for identifying which world is using this transition function
        uint32 x = input[uint(M.x)];
        uint32 y = input[uint(M.y)];
        uint32 spawn = input[uint(M.spawn)];
        uint32 flee = input[uint(M.flee)];
        uint32 toss = input[uint(M.toss)];
        uint32 move = input[uint(M.move)];

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

    function _throwBall() internal {
    bytes32 player = addressToEntityKey(_msgSender());

    EncounterData memory encounter = Encounter.get(player);
    require(encounter.exists, "not in encounter");

    uint256 rand = uint256(keccak256(abi.encode(player, encounter.monster, encounter.catchAttempts, blockhash(block.number - 1), block.difficulty)));
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

    function _flee() internal {
    bytes32 player = addressToEntityKey(_msgSender());

    EncounterData memory encounter = Encounter.get(player);
    require(encounter.exists, "not in encounter");

    Monster.deleteRecord(encounter.monster);
    Encounter.deleteRecord(player);
    }

    function _spawn(uint32 x, uint32 y) internal {
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

    function _move(uint32 x, uint32 y) internal {
    bytes32 player = addressToEntityKey(_msgSender());
    require(Movable.get(player), "cannot move");

    require(!Encounter.getExists(player), "cannot move during an encounter");

    (uint32 fromX, uint32 fromY) = Position.get(player);
    require(_distance(fromX, fromY, x, y) == 1, "can only move to adjacent spaces");

    // Constrain position to map size, wrapping around if necessary
    (uint32 width, uint32 height, ) = MapConfig.get();
    x = (x + width) % width;
    y = (y + height) % height;

    bytes32 position = positionToEntityKey(x, y);
    require(!Obstruction.get(position), "this space is obstructed");

    Position.set(player, x, y);

    // require(false, toAsciiString(_msgSender()));

    if (Encounterable.get(player) && EncounterTrigger.get(position)) {
        uint256 rand = uint256(keccak256(abi.encode(player, position, blockhash(block.number - 1), block.difficulty)));
        if (rand % 5 == 0) {
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
    MonsterType monsterType = MonsterType((uint256(monster) % uint256(type(MonsterType).max)) + 1);
    Monster.set(monster, monsterType);
    Encounter.set(player, EncounterData({exists: true, monster: monster, catchAttempts: 0}));
    }

    // function toAsciiString(address x) internal pure returns (string memory) {
    // bytes memory s = new bytes(40);
    // for (uint i = 0; i < 20; i++) {
    //     bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
    //     bytes1 hi = bytes1(uint8(b) / 16);
    //     bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
    //     s[2*i] = char(hi);
    //     s[2*i+1] = char(lo);            
    // }
    // return string(s);
    // }

    // function char(bytes1 b) internal pure returns (bytes1 c) {
    //     if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
    //     else return bytes1(uint8(b) + 0x57);
    // }
//}
