// %%raw("import 'nes.css/css/nes.min.css'")

switch ReactDOM.querySelector("#pomo-root") {
| Some(rootElement) => {
    let root = ReactDOM.Client.createRoot(rootElement)
    ReactDOM.Client.Root.render(root, <Pomo />)
  }
| None => ()
}
