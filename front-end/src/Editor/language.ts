import { LRLanguage, StreamLanguage } from "@codemirror/language";
import { parser } from "./host.grammar";
import { LanguageSupport } from "@codemirror/language";
import { styleTags, tags as t } from "@lezer/highlight";

export const ipHostHighlighting = styleTags({
  comment: t.comment,
  // IP: t.number,
  // Host: t.string,
});

export const ipHostLanguage = LRLanguage.define({
  parser: parser.configure({
    props: [ipHostHighlighting],
  }),
});

export function ipHost() {
  return new LanguageSupport(ipHostLanguage);
}

export const simpleDslParser = StreamLanguage.define({
  startState: () => ({ inLine: true }),

  token: (stream, state) => {
    // 跳过空格
    //
    stream.eatSpace();
    console.log("aaaa");
    // 检查注释
    if (stream.peek() === "#") {
      stream.skipToEnd();
      return "comment";
    }

    // 尝试匹配 IP 地址
    const ipMatch = stream.match(
      /^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)/,
      false,
    );
    if (ipMatch) {
      stream.match(
        /^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)/,
      );
      return "ip";
    }

    // 匹配主机名
    if (stream.match(/^[a-zA-Z0-9\-\._]+/)) {
      return "host";
    }

    // 其他字符
    stream.next();
    return null;
  },

  blankLine: (state) => {
    state.inLine = true;
    return state;
  },
});
