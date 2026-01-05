import "./app.less";
import HostConfig from "./HostConfig";
import Editor from "./Editor";
import { useEffect, useMemo, useRef, useState } from "preact/hooks";
import { type Host, AppContext } from "./context";
import HostState from "./HostState";
import { request, updateHostApi } from "./request";

/**
 * AppContextState
 * @returns
 */
export function App() {
  /**
   * hostList
   */
  const [hostList, setHostList] = useState<Host[]>([
    {
      id: 0,
      name: `系统 host`,
      open: false,
      content: "",
    },
  ]);
  const [current, setCurrent] = useState(0);
  const currentHost = useMemo(() => {
    return hostList.find((i) => i?.id === current) || hostList[0];
  }, [hostList, current]);

  useEffect(() => {
    request("/api/getHostList").then((result) => {
      setCurrent(0);
      setHostList((v) => v.concat(result.hosts));
    });
  }, []);
  const editor = useRef<any>(null);
  useEffect(() => {
    if (currentHost?.id === 0) {
      request("/api/sysHost").then((result: any) => {
        setHostList((v) => [result].concat(v.slice(1)));
        editor.current?.update(result.content);
      });
    }
  }, [currentHost?.id]);

  return (
    <AppContext.Provider
      value={{ hostList, setHostList, currentHost, setCurrent }}
    >
      <div className="z-page">
        <div className="z-sider">
          <div className="z-header">
            <div className="z-logo">
              <span className="z-logo-text">Zhost</span>
            </div>
            <HostConfig />
          </div>
        </div>

        <div className="z-content">
          <HostState />
          {currentHost && (
            <Editor
              ref={editor}
              key={currentHost?.id}
              readonly={currentHost?.id === 0}
              value={currentHost?.content || ""}
              onChange={(content) => {
                if (currentHost?.id === 0) return;
                currentHost.content = content;
                setHostList((v) => v.concat([]));
                updateHostApi(currentHost);
              }}
            />
          )}
        </div>
      </div>
    </AppContext.Provider>
  );
}
