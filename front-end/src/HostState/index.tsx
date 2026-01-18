import { useAppContext } from "../context";
import { updateHostApi } from "../request";
import { cls } from "../utils";
import "./index.less";
import { Switch, Tag, Tooltip } from "antd";

const HostState = () => {
  const { currentHost, setHostList } = useAppContext();
  const isSystemHost = currentHost?.id === 0;
  return (
    <div className="z-host-state">
      <div className="z-host-state-content">
        <div className="z-host-state-title">
          {currentHost?.name || "Unknown Host"}
        </div>
        <div className={cls("z-host-state-switch", isSystemHost && "z-hide")}>
          <Tooltip title="生效后写入系统host文件">
            <span className="z-host-state-switch-text">生效</span>
          </Tooltip>
          <Switch
            onChange={(checked) => {
              currentHost.open = checked;
              setHostList((v) => {
                const index = v.findIndex((h) => h.id === currentHost?.id);
                if (index !== -1) {
                  v[index] = { ...currentHost, open: checked };
                }
                return v.concat([]);
              });
              updateHostApi(currentHost);
            }}
            checked={currentHost?.open}
          />
        </div>
        {isSystemHost && (
          <Tooltip placement="right" title="根据配置生成，无需直接编辑 ✍️">
            <Tag variant="solid">只读</Tag>
          </Tooltip>
        )}
      </div>
    </div>
  );
};

export default HostState;
