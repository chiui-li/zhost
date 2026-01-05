import {
  useEffect,
  useRef,
  forwardRef,
  useImperativeHandle,
} from "preact/compat";
import { EditorView, lineNumbers, gutter } from "@codemirror/view";
import { EditorState } from "@codemirror/state";
import "./index.less";

export interface Props {
  value: string;
  onChange: (value: string) => void;
  readonly?: boolean;
}

const fullHeightTheme = EditorView.theme({});

function Editor({ value, onChange, readonly = false }: Props, ref: any) {
  const editorRef = useRef<HTMLDivElement>(null);
  const codeMirrorIns = useRef<EditorView>();
  useEffect(() => {
    if (editorRef.current) {
      codeMirrorIns.current = new EditorView({
        state: EditorState.create({
          doc: value,
          extensions: [
            EditorState.readOnly.of(readonly),
            EditorView.updateListener.of((v) => {
              if (v.docChanged) {
                onChange(codeMirrorIns.current!.state.doc.toString());
              }
            }),
            lineNumbers(),
            gutter({
              renderEmptyElements: true,
            }),
            fullHeightTheme,
          ],
        }),
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
