import { render } from "preact";
import { App } from "./app.tsx";
import "./reset.less";

render(<App />, document.getElementById("app")!);
