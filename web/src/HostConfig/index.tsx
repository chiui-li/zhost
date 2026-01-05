import React from "preact/compat";
import "./index.less";
import { PlusOutlined } from "@ant-design/icons";
import { Badge, Tooltip } from "antd";
import { cls } from "../utils";
import QueueAnim from "rc-queue-anim";
import { useAppContext } from "../context";
import { addNewHost } from "../request";
let i = 0;
function HostConfig() {
  const { hostList, setHostList, currentHost, setCurrent } = useAppContext();
  return (
    <div className="z-host-config">
      <div className="z-group">
        <div className="z-group-name">
          <span>HOST</span>
          <span className="z-item-add">
            <Tooltip placement="right" title="添加host配置">
              <PlusOutlined
                onClick={() => {
                  const timestamp = Date.now();
                  const newHost = {
                    id: timestamp + i,
                    name: `host 配置`,
                    open: false,
                    content: "www.demo.com 127.0.0.1",
                  };
                  i++;
                  setHostList(hostList.concat([newHost]));
                  addNewHost(newHost);
                }}
              />
            </Tooltip>
          </span>
        </div>
        <QueueAnim delay={100} className="z-group-items">
          {hostList.map((host) => (
            <div
              key={host.id}
              onClick={() => {
                setCurrent(host.id);
              }}
              className={cls(
                "z-item-box",
                currentHost?.id === host.id && "z-item-active",
                host.id === 0 && "z-item-system",
              )}
            >
              <div
                className={cls(host.open && "z-item-open", "z-item-box-name")}
              >
                {host.name}
              </div>
              {host.open && (
                <Tooltip placement="right" title="当前配置已写入系统 host 文件">
                  <span>
                    <Badge status="processing" className="z-item-box-badge" />
                  </span>
                </Tooltip>
              )}
            </div>
          ))}
        </QueueAnim>
      </div>
    </div>
  );
}

export default React.memo(HostConfig, () => true);
