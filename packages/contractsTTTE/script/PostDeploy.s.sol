// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { IWorld } from "../src/codegen/world/IWorld.sol";
import { EncounterTrigger1, MapConfig1, Obstruction1, Position1 } from "../src/codegen/Tables.sol";
import { TerrainType1 } from "../src/codegen/Types.sol";
import { MapConfig2, Obstruction2 } from "../src/codegen/Tables.sol";
import { TerrainType2, MarkerType2 } from "../src/codegen/Types.sol";
import { positionToEntityKey } from "../src/positionToEntityKey.sol";

contract PostDeploy is Script {
  function run(address worldAddress) external {
    console.log("Deployed world: ", worldAddress);
    IWorld world = IWorld(worldAddress);

    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    vm.startBroadcast(deployerPrivateKey);

    TerrainType1 O = TerrainType1.None;
    TerrainType1 T = TerrainType1.TallGrass;
    TerrainType1 B = TerrainType1.Boulder;

    TerrainType1[20][20] memory map = [
      [O, O, O, O, O, O, T, O, O, O, O, O, O, O, O, O, O, O, O, O],
      [O, O, T, O, O, O, O, O, T, O, O, O, O, B, O, O, O, O, O, O],
      [O, T, T, T, T, O, O, O, O, O, O, O, O, O, O, T, T, O, O, O],
      [O, O, T, T, T, T, O, O, O, O, B, O, O, O, O, O, T, O, O, O],
      [O, O, O, O, T, T, O, O, O, O, O, O, O, O, O, O, O, T, O, O],
      [O, O, O, B, B, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O],
      [O, T, O, O, O, B, B, O, O, O, O, T, O, O, O, O, O, B, O, O],
      [O, O, T, T, O, O, O, O, O, T, O, B, O, O, T, O, B, O, O, O],
      [O, O, T, O, O, O, O, T, T, T, O, B, B, O, O, O, O, O, O, O],
      [O, O, O, O, O, O, O, T, T, T, O, B, T, O, T, T, O, O, O, O],
      [O, B, O, O, O, B, O, O, T, T, O, B, O, O, T, T, O, O, O, O],
      [O, O, B, O, O, O, T, O, T, T, O, O, B, T, T, T, O, O, O, O],
      [O, O, B, B, O, O, O, O, T, O, O, O, B, O, T, O, O, O, O, O],
      [O, O, O, B, B, O, O, O, O, O, O, O, O, B, O, T, O, O, O, O],
      [O, O, O, O, B, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O],
      [O, O, O, O, O, O, O, O, O, O, B, B, O, O, T, O, O, O, O, O],
      [O, O, O, O, T, O, O, O, T, B, O, O, O, T, T, O, B, O, O, O],
      [O, O, O, T, O, T, T, T, O, O, O, O, O, T, O, O, O, O, O, O],
      [O, O, O, T, T, T, T, O, O, O, O, T, O, O, O, T, O, O, O, O],
      [O, O, O, O, O, T, O, O, O, O, O, O, O, O, O, O, O, O, O, O]
    ];

    uint32 height = uint32(map.length);
    uint32 width = uint32(map[0].length);
    bytes memory terrain = new bytes(width * height);

    for (uint32 y = 0; y < height; y++) {
      for (uint32 x = 0; x < width; x++) {
        TerrainType1 terrainType = map[y][x];
        if (terrainType == TerrainType1.None) continue;

        terrain[(y * width) + x] = bytes1(uint8(terrainType));

        bytes32 entity = positionToEntityKey(x, y);
        if (terrainType == TerrainType1.Boulder) {
          Position1.set(world, entity, x, y);
          Obstruction1.set(world, entity, true);
        } else if (terrainType == TerrainType1.TallGrass) {
          Position1.set(world, entity, x, y);
          EncounterTrigger1.set(world, entity, true);
        }
      }
    }

    MapConfig1.set(world, width, height, terrain);


    // TerrainType2 O2 = TerrainType2.None;

    // TerrainType2[3][3] memory map2 = [
    //   [O2, O2, O2],
    //   [O2, O2, O2],
    //   [O2, O2, O2]
    // ];

    uint32 height2 = uint32(3);
    uint32 width2 = uint32(3);
    bytes memory terrain2 = new bytes(width2 * height2);

    for (uint32 y = 0; y < height2; y++) {
      for (uint32 x = 0; x < width2; x++) {
        
        bytes32 entity = positionToEntityKey(x, y);
        Obstruction2.set(world, entity, MarkerType2.None);        
      }
    }

    MapConfig2.set(world, width2, height2, terrain2);


    vm.stopBroadcast();
  }
}
