export enum TerrainType {
  X=1,
  O
}

type TerrainConfig = {
  emoji: string;
};

export const terrainTypes: Record<TerrainType, TerrainConfig> = {
 
  [TerrainType.X]: {
    emoji: "X",
  },
  [TerrainType.O]: {
    emoji: "O",
  },
};
