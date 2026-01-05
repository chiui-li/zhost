import { createContext, useContext, type Dispatch } from "preact/compat";
import type { StateUpdater } from "preact/hooks";

export interface Host {
  id: number;
  name: string;
  open: boolean;
  content: string;
}

export interface AppContextState {
  hostList: Host[];
  currentHost: Host;
  setHostList: Dispatch<StateUpdater<Host[]>>;
  setCurrentHost?: Dispatch<StateUpdater<Host>>;
  setCurrent: Dispatch<StateUpdater<number>>;
}

export const AppContext = createContext<AppContextState>({
  hostList: [],
  setHostList: () => {},
  currentHost: {
    id: 0,
    name: "系统 HOST",
    open: false,
    content: "",
  },
  setCurrent: () => {},
  setCurrentHost: () => {},
});

export const useAppContext = () => useContext(AppContext);
