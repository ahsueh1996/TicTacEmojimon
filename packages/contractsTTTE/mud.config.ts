import { mudConfig } from "@latticexyz/world/register";

export default mudConfig({
  enums: {
    MonsterCatchResult1: ["Missed", "Caught", "Fled"],
    MonsterType1: ["None", "Eagle", "Rat", "Caterpillar"],
    TerrainType1: ["None", "TallGrass", "Boulder"],    
    MarkerType2: ["None", "X", "O"],
    TerrainType2: ["None"],
  },
  tables: {
    Encounter1: {
      keySchema: {
        player: "bytes32",
      },
      schema: {
        exists: "bool",
        monster: "bytes32",
        catchAttempts: "uint256",
      },
    },
    EncounterTrigger1: "bool",
    Encounterable1: "bool",
    MapConfig1: {
      keySchema: {},
      dataStruct: false,
      schema: {
        width: "uint32",
        height: "uint32",
        terrain: "bytes",
      },
    },
    MonsterCatchAttempt1: {
      ephemeral: true,
      dataStruct: false,
      keySchema: {
        encounter: "bytes32",
      },
      schema: {
        result: "MonsterCatchResult",
      },
    },
    Monster1: "MonsterType",
    Movable1: "bool",
    Obstruction1: "bool",
    OwnedBy1: "bytes32",
    Player1: "bool",
    Position1: {
      dataStruct: false,
      schema: {
        x: "uint32",
        y: "uint32",
      },
    },
    MapConfig2: {
      keySchema: {},
      dataStruct: false,
      schema: {
        width: "uint32",
        height: "uint32",
        terrain: "bytes",
      },
    },
    Marker2: "MarkerType",
    Obstruction2: "MarkerType",
    OwnedBy2: "bytes32",
    Player2: "bool",
    Winner2: {
      keySchema:{},
      schema: {
        marker: "MarkerType"
      }
    },
    Position2: {
      dataStruct: false,
      schema: {
        x: "uint32",
        y: "uint32",
      },
    },
    Map3:{
      keySchema: { position: "bytes32"},
      dataStruct: false,
      schema: {
        monster:"MonsterType",
        ownedBy: "bytes32"
      }
    },
    Winner3:"bytes32"
  },
});
