import React, { useState } from "preact/compat";
import "./index.less";
import { EditFilled, PlusOutlined } from "@ant-design/icons";
import { Badge, Form, Modal, Tooltip, Input } from "antd";
import { cls } from "../utils";
import QueueAnim from "rc-queue-anim";
import { useAppContext } from "../context";
import { addNewHost, updateHostApi } from "../request";

let i = 0;

function HostConfig() {
  const { hostList, setHostList, currentHost, setCurrent } = useAppContext();
  const [open, setOpen] = useState(false);
  const [form] = Form.useForm();

  //
  const add = () => {
    const timestamp = Date.now();
    const newHost = {
      id: timestamp + i,
      name: `host 配置`,
      open: false,
      content: "www.demo.com 127.0.0.1",
    };
    i++;
    if (hostList.find((item) => item.id === newHost.id)) {
      return add();
    }
    setHostList(hostList.concat([newHost]));
    addNewHost(newHost);
  };
  return (
    <div className="z-host-config">
      <div className="z-group">
        <div className="z-group-name">
          <span>HOST</span>
          <span className="z-item-add">
            <Tooltip placement="right" title="添加host配置">
              <PlusOutlined onClick={add} />
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
              {host.open && (
                <Tooltip placement="right" title="当前配置已写入系统 host 文件">
                  <span>
                    <Badge status="processing" className="z-item-box-badge" />
                  </span>
                </Tooltip>
              )}
              <div
                className={cls(host.open && "z-item-open", "z-item-box-name")}
              >
                {host.name}
              </div>
              {host.id !== 0 && (
                <EditFilled
                  onClick={() => {
                    form.setFieldsValue({ ...host });
                    setOpen(true);
                  }}
                  className={cls("z-item-box-edit")}
                />
              )}
            </div>
          ))}
        </QueueAnim>
        <Modal
          open={open}
          className="update-modal"
          title="编辑"
          cancelText="取消"
          okText="确定"
          onCancel={() => setOpen(false)}
          onOk={() => {
            form.validateFields().then((values) => {
              setHostList((prev) =>
                prev.map((item) => {
                  if (item.id === currentHost?.id) {
                    const n = { ...item, ...values };
                    updateHostApi(n);
                    return n;
                  }
                  return item;
                }),
              );
              setOpen(false);
            });
          }}
        >
          <Form form={form} className="update-form" size="small">
            <Form.Item
              rules={[
                {
                  required: true,
                  max: 16,
                },
              ]}
              name="name"
              label="名称"
            >
              <Input size="small" />
            </Form.Item>
          </Form>
        </Modal>
      </div>
    </div>
  );
}

export default React.memo(HostConfig, () => true);
