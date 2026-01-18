import {
  useEffect,
  useRef,
  forwardRef,
  useImperativeHandle,
  type Ref,
} from "react";
import { javascript } from "@codemirror/lang-javascript";
import "./index.less";
import { EditorView, basicSetup } from "codemirror";
import { EditorState } from "@codemirror/state";

export interface Props {
  value: string;
  onChange: (value: string) => void;
  readonly?: boolean;
}

// const fullHeightTheme = EditorView.theme({});

function Editor(
  { value, onChange, readonly = false }: Props,
  ref: Ref<unknown>,
) {
  const editorRef = useRef<HTMLDivElement>(null);
  const codeMirrorIns = useRef<EditorView>(null);
  useEffect(() => {
    if (editorRef.current) {
      codeMirrorIns.current = new EditorView({
        doc: value,
        extensions: [
          basicSetup,
          javascript(),
          EditorState.readOnly.of(readonly),
          EditorView.updateListener.of((v) => {
            if (v.docChanged) {
              onChange(codeMirrorIns.current!.state.doc.toString());
            }
          }),
        ],
        parent: editorRef.current,
      });
      return () => {
        codeMirrorIns.current?.destroy();
      };
    }
  }, []);

  useImperativeHandle(ref, () => {
    return {
      update(v: string) {
        codeMirrorIns.current?.dispatch({
          changes: {
            from: 0,
            to: codeMirrorIns.current?.state.doc.length,
            insert: v,
          },
        });
      },
    };
  });

  return (
    <div className="z-host-editor">
      <div ref={editorRef} className="z-host-editor-ins" />
    </div>
  );
}

export default forwardRef(Editor);
