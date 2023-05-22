import { mudConfig } from "@latticexyz/world/register";

export default mudConfig({
  enums: {
    MarkerType: ["None", "X", "O"],
    TerrainType: ["None"],
  },
  tables: {
    MapConfig: {
      keySchema: {},
      dataStruct: false,
      schema: {
        width: "uint32",
        height: "uint32",
        terrain: "bytes",
      },
    },
    Marker: "MarkerType",
    Obstruction: "MarkerType",
    OwnedBy: "bytes32",
    Player: "bool",
    Winner: {
      keySchema:{},
      schema: {
        marker: "MarkerType"
      }
    },
    Position: {
      dataStruct: false,
      schema: {
        x: "uint32",
        y: "uint32",
      },
    },
  },
});
