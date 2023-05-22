// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { IWorld } from "../src/codegen/world/IWorld.sol";
import { MapConfig, Obstruction } from "../src/codegen/Tables.sol";
import { TerrainType, MarkerType } from "../src/codegen/Types.sol";
import { positionToEntityKey } from "../src/positionToEntityKey.sol";

contract PostDeploy is Script {
  function run(address worldAddress) external {
    console.log("Deployed world: ", worldAddress);
    IWorld world = IWorld(worldAddress);

    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    vm.startBroadcast(deployerPrivateKey);

    TerrainType O = TerrainType.None;

    TerrainType[3][3] memory map = [
      [O, O, O],
      [O, O, O],
      [O, O, O]
    ];

    uint32 height = uint32(map.length);
    uint32 width = uint32(map[0].length);
    bytes memory terrain = new bytes(width * height);

    for (uint32 y = 0; y < height; y++) {
      for (uint32 x = 0; x < width; x++) {
        TerrainType terrainType = map[y][x];
        
        bytes32 entity = positionToEntityKey(x, y);
        Obstruction.set(world, entity, MarkerType.None);        
      }
    }

    MapConfig.set(world, width, height, terrain);

    vm.stopBroadcast();
  }
}
