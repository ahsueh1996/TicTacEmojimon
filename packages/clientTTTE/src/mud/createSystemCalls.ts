import { Has, HasValue, getComponentValue, runQuery } from "@latticexyz/recs";
import { uuid, awaitStreamValue } from "@latticexyz/utils";
import { MonsterCatchResult } from "../monsterCatchResult";
import { ClientComponents } from "./createClientComponents";
import { SetupNetworkResult } from "./setupNetwork";
import { MonsterType } from "../monsterTypes";
import { utils } from '../../node_modules/ethers';
import { world } from './world'

export type SystemCalls = ReturnType<typeof createSystemCalls>;

export function createSystemCalls(
  { playerEntity, singletonEntity, worldSend, txReduced$ }: SetupNetworkResult,
  {
    Encounter1,
    MapConfig1,
    MonsterCatchAttempt1,
    Obstruction1,
    Player1,
    Position1,
  }: ClientComponents
) {
  const wrapPosition = (x: number, y: number) => {
    const mapConfig = getComponentValue(MapConfig1, singletonEntity);
    if (!mapConfig) {
      throw new Error("mapConfig no yet loaded or initialized");
    }
    return [
      (x + mapConfig.width) % mapConfig.width,
      (y + mapConfig.height) % mapConfig.height,
    ];
  };

  const isObstructed = (x: number, y: number) => {
    return runQuery([Has(Obstruction1), HasValue(Position1, { x, y })]).size > 0;
  };

  const moveTo = async (inputX: number, inputY: number) => {
    if (!playerEntity) {
      throw new Error("no player");
    }

    const inEncounter = !!getComponentValue(Encounter1, playerEntity);
    if (inEncounter) {
      console.warn("cannot move while in encounter");
      return;
    }

    const [x, y] = wrapPosition(inputX, inputY);
    if (isObstructed(x, y)) {
      console.warn("cannot move to obstructed space");
      return;
    }

    const positionId = uuid();
    Position1.addOverride(positionId, {
      entity: playerEntity,
      value: { x, y },
    });

    try {
      //const tx = await worldSend("move", [x, y]);
      const tx = await worldSend("F3", [[x, y,0,0,0,1]]);
      await awaitStreamValue(txReduced$, (txHash) => txHash === tx.hash);
    } finally {
      Position1.removeOverride(positionId);
    }
  };

  const moveBy = async (deltaX: number, deltaY: number) => {
    if (!playerEntity) {
      throw new Error("no player");
    }

    const playerPosition = getComponentValue(Position1, playerEntity);
    if (!playerPosition) {
      console.warn("cannot moveBy without a player position, not yet spawned?");
      return;
    }

    await moveTo(playerPosition.x + deltaX, playerPosition.y + deltaY);
  };

  const spawn = async (inputX: number, inputY: number) => {
    if (!playerEntity) {
      throw new Error("no player");
    }

    const canSpawn = getComponentValue(Player1, playerEntity)?.value !== true;
    if (!canSpawn) {
      throw new Error("already spawned");
    }

    const [x, y] = wrapPosition(inputX, inputY);
    if (isObstructed(x, y)) {
      console.warn("cannot spawn on obstructed space");
      return;
    }

    const positionId = uuid();
    Position1.addOverride(positionId, {
      entity: playerEntity,
      value: { x, y },
    });
    const playerId = uuid();
    Player1.addOverride(playerId, {
      entity: playerEntity,
      value: { value: true },
    });

    try {
      // const tx = await worldSend("spawn", [x, y]);
      const tx = await worldSend("F3", [[x, y,1,0,0,0]]);
      await awaitStreamValue(txReduced$, (txHash) => txHash === tx.hash);
    } finally {
      Position1.removeOverride(positionId);
      Player1.removeOverride(playerId);
    }
  };

  const throwBall = async () => {
    const player = playerEntity;
    if (!player) {
      throw new Error("no player");
    }

    const encounter = getComponentValue(Encounter1, player);
    if (!encounter) {
      throw new Error("no encounter");
    }

    // const tx = await worldSend("throwBall", []);    
    const tx = await worldSend("F3", [[0,0,0,0,1,0]]);
    await awaitStreamValue(txReduced$, (txHash) => txHash === tx.hash);

    const catchAttempt = getComponentValue(MonsterCatchAttempt1, player);
    if (!catchAttempt) {
      throw new Error("no catch attempt found");
    }

    return catchAttempt.result as MonsterCatchResult;
  };

  const fleeEncounter = async () => {
    // const tx = await worldSend("flee", []);
    const tx = await worldSend("F3", [[0,0,0,1,0,0]]);
    await awaitStreamValue(txReduced$, (txHash) => txHash === tx.hash);
  };

  const positionToEntity = async (x: number, y: number) => {
    //https://github.com/ethers-io/ethers.js/issues/718
    const hex = utils.sha256(
      utils.defaultAbiCoder.encode(["uint", "uint"], [x, y])
    );
    // from https://mud.dev/client-side#reading-component-value-directly
    // const entityID = hex as EntityID;
    const entity = world.registerEntity({ id: hex })
    return entity
  };

  const getMapMonsterType = async(x:number,y:number) => {
    const positionEntity = await positionToEntity(x,y);
    const monster = getComponentValue(Map3, positionEntity);
    if (!monster) {
      // throw new Error("no monster here");
      return MonsterType.None;
    }
    return monster.monster as MonsterType 
  };

  return {
    moveTo,
    moveBy,
    spawn,
    throwBall,
    fleeEncounter,
    getMapMonsterType,
  };
}


