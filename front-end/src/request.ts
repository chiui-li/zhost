import { ZON } from "zzon";
import type { Host } from "./context";
import { message } from "antd";

function decodeZonString(zonStr: string) {
  const s = zonStr;
  const bytes = [];
  for (let i = 0; i < s.length; ) {
    if (s[i] === "\\" && s[i + 1] === "x") {
      bytes.push(parseInt(s.slice(i + 2, i + 4), 16));
      i += 4;
    } else {
      bytes.push(s.charCodeAt(i));
      i += 1;
    }
  }
  return new TextDecoder("utf-8").decode(new Uint8Array(bytes));
}

export async function request(
  url: string,
  options?: RequestInit,
): Promise<Record<string, any>> {
  const response = await fetch(`http://localhost:3000${url}`, options).catch(
    () => {
      message.error("Network error");
    },
  );
  const text = await response?.text().catch(() => {
    message.error("Failed to parse response");
    return Promise.reject(new Error("Failed to parse response"));
  });
  if (text === undefined) {
    return Promise.reject(new Error("Failed to parse response"));
  }
  const json = ZON.parse(text, (_, v) => {
    if (typeof v === "string") {
      return decodeZonString(v).replaceAll("\\n", "\n");
    }
    return v;
  });
  return json;
}

export async function updateHostApi(host: Host) {
  return request("/api/updateHost", {
    method: "post",
    headers: {
      "Content-Type": "text/plain; charset=utf-8",
    },
    body: ZON.stringify(host),
  });
}

export async function addNewHost(host: Host) {
  return request("/api/addNewHost", {
    method: "post",
    headers: {
      "Content-Type": "text/plain; charset=utf-8",
    },
    body: ZON.stringify(host),
  });
}
