import { createContext, useContext, type Dispatch } from "react";

export interface Host {
  id: number;
  name: string;
  open: boolean;
  content: string;
}

export interface AppContextState {
  hostList: Host[];
  currentHost: Host;
  setHostList: any;
  setCurrentHost?: any;
  setCurrent: any;
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
