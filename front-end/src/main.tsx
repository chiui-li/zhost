import { App } from "./app.tsx";
import "./reset.less";

import React from "react";
import ReactDOM from "react-dom/client";
const root = document.getElementById("root");

if (root) {
  ReactDOM.createRoot(root).render(React.createElement(App));
}
