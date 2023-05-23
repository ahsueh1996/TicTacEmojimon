export enum TerrainType {
  TallGrass = 1,
  Boulder,X,O
}

type TerrainConfig = {
  emoji: string;
};

export const terrainTypes: Record<TerrainType, TerrainConfig> = {
  [TerrainType.TallGrass]: {
    emoji: "🌳",
  },
  [TerrainType.Boulder]: {
    emoji: "🛢️",
  },
  
  [TerrainType.X]: {
    emoji: "X",
  },
  [TerrainType.O]: {
    emoji: "O",
  },
};
