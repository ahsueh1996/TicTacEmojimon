import { useComponentValue, useEntityQuery } from "@latticexyz/react";
import { GameMap } from "./GameMap";
import { useMUD } from "./MUDContext";
import { useKeyboardMovement } from "./useKeyboardMovement";
import { hexToArray } from "@latticexyz/utils";
import { TerrainType, terrainTypes } from "./terrainTypes";
import { EncounterScreen } from "./EncounterScreen";
import { Entity, Has, getComponentValueStrict } from "@latticexyz/recs";
import { MonsterType, monsterTypes } from "./monsterTypes";

export const GameBoard = () => {
  useKeyboardMovement();

  const {
    components: { Encounter1, MapConfig1, Monster1, Player1, Position1 },
    network: { playerEntity, singletonEntity },
    systemCalls: { spawn, getMapMonsterType, getWin },
  } = useMUD();

  const canSpawn = useComponentValue(Player1, playerEntity)?.value !== true;

  const players = useEntityQuery([Has(Player1), Has(Position1)]).map((entity) => {
    const position = getComponentValueStrict(Position1, entity);
    return {
      entity,
      x: position.x,
      y: position.y,
      emoji: entity === playerEntity ? "🤠" : "🥸",
    };
  });

  const mapConfig = useComponentValue(MapConfig1, singletonEntity);
  if (mapConfig == null) {
    throw new Error(
      "map config not set or not ready, only use this hook after loading state === LIVE"
    );
  }

  const { width, height, terrain: terrainData } = mapConfig;
  const terrain = Array.from(hexToArray(terrainData)).map((value, index) => {
    let { emoji } =
      value in TerrainType ? terrainTypes[value as TerrainType] : { emoji: "" };
    if (emoji==terrainTypes[TerrainType.Boulder].emoji && getWin()){
      emoji = "🎉";
    }
    const _x = index % width;
    const _y = Math.floor(index / width);
    let mt = getMapMonsterType(_x,_y);
    if (mt != MonsterType.None) {        
      emoji = monsterTypes[mt as MonsterType].emoji;
    } 
    return {
      x: _x,
      y: _y,
      emoji,
    };
  });

  const encounter = useComponentValue(Encounter1, playerEntity);
  const monsterType = useComponentValue(
    Monster1,
    encounter ? (encounter.monster as Entity) : undefined
  )?.value;
  const monster =
    monsterType != null && monsterType in MonsterType
      ? monsterTypes[monsterType as MonsterType]
      : null;

  return (
    <GameMap
      width={width}
      height={height}
      terrain={terrain}
      onTileClick={canSpawn ? spawn : undefined}
      players={players}
      encounter={
        encounter ? (
          <EncounterScreen
            monsterName={monster?.name ?? "MissingName"}
            monsterEmoji={monster?.emoji ?? "💱"}
          />
        ) : undefined
      }
    />
  );
};
