import { useEffect } from "react";
import { useMUD } from "./MUDContext";
import { resolveTableId } from "@latticexyz/world/register";

export const useKeyboardMovement = () => {
  const {
    systemCalls: { moveBy, putMarker, reset},
  } = useMUD();

  useEffect(() => {
    const listener = (e: KeyboardEvent) => {
      if (e.key === "ArrowUp") {
        moveBy(0, -1);
      }
      if (e.key === "ArrowDown") {
        moveBy(0, 1);
      }
      if (e.key === "ArrowLeft") {
        moveBy(-1, 0);
      }
      if (e.key === "ArrowRight") {
        moveBy(1, 0);
      }
      if (e.key === " "){
        putMarker();
      }
      if (e.key === "r"){
        reset();
      }
    };

    window.addEventListener("keydown", listener);
    return () => window.removeEventListener("keydown", listener);
  }, [moveBy]);
};
