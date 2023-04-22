module Mode = {
  type t = Work | ShortBreak | LongBreak | Idle

  let toString = x =>
    switch x {
    | Work => "Work"
    | ShortBreak => "Short break"
    | LongBreak | Idle => "Long break" // Idle won't be printed
    }

  let toCSS = x =>
    switch x {
    | Work => " is-primary"
    | Idle => ""
    | ShortBreak => " is-success"
    | LongBreak => " is-warning"
    }
}

module Button = {
  @react.component
  let make = (~disabled, ~onClick, ~class, ~text) => {
    let className = "nes-btn" ++ (disabled ? " is-disabled" : class->Mode.toCSS)

    <button
      disabled onClick type_="button" className style={ReactDOM.Style.make(~margin="1.5rem", ())}>
      {React.string(text)}
    </button>
  }
}

module TimeDisplay = {
  let to2digits = x => (x > 9 ? "" : "0") ++ x->Belt.Int.toString

  @react.component
  let make = (~remaining, ~mode) => {
    let min = remaining / 60
    let sec = remaining->mod(60)
    let display = min->to2digits ++ ":" ++ sec->to2digits

    <p
      className={"nes-text" ++ mode->Mode.toCSS}
      style={ReactDOM.Style.make(~fontSize="clamp(1rem, 15vw, 3rem)", ())}>
      <time> {React.string(display)} </time>
    </p>
  }
}

module Progress = {
  @react.component
  let make = (~value, ~mode) => {
    let className = "nes-progress" ++ mode->Mode.toCSS
    <progress className value={value->Belt.Float.toString} />
  }
}

module History = {
  @react.component
  let make = (~history) => {
    <div className="lists" style={ReactDOM.Style.make(~textAlign="left", ())}>
      <ul className="nes-list is-disc">
        {Belt.Array.mapWithIndex(history, (id, mode) =>
          <li key={id->Belt.Int.toString} className={"nes-text" ++ mode->Mode.toCSS}>
            {mode->Mode.toString->React.string}
          </li>
        )->React.array}
      </ul>
    </div>
  }
}

@module("worker-timers")
external setTimeout: (unit => unit, int) => Js.Global.timeoutId = "setTimeout"

@module("worker-timers")
external clearTimeout: Js.Global.timeoutId => unit = "clearTimeout"

@react.component
let make = () => {
  open React
  open Mode

  let secondsPerMinute = 60 // for debugging

  let (passed, setPassed) = useState(_ => 0)
  let (total, setTotal) = useState(_ => 0)
  let (progress, setProgress) = useState(_ => 0.)
  let (paused, setPaused) = useState(_ => false)
  let (mode, setMode) = useState(_ => Idle)
  let (history, setHistory) = useState(_ => ([] :> array<Mode.t>))

  let switchToMode = m => {
    setMode(_ => m)
    setPassed(_ => 0)
    setProgress(_ => 0.)
  }

  useEffect0(_ => {
    let _ = "/sw.js"->Notification.ServiceWorkerRegistration.register
    None
  })

  useEffect1(_ => {
    setTotal(_ =>
      switch mode {
      | Work => 25 * secondsPerMinute
      | ShortBreak => 5 * secondsPerMinute
      | LongBreak => 15 * secondsPerMinute
      | Idle => 0
      }
    )
    None
  }, [mode])

  useEffect3(_ => {
    let id = setTimeout(_ =>
      if !paused && passed < total {
        // In Idle mode, passed always equal to total (0)
        let passed = passed + 1
        if passed == total {
          // TODO check is focused
          let _ = switch mode {
          | Work => "Work period finished, time for a break!"
          | ShortBreak => "Short break finished, time to work!"
          | LongBreak | Idle => "Long break finished, time to work!"
          }->Notification.make
          setHistory(history => [mode]->Belt.Array.concat(history))
          Idle->switchToMode
        } else {
          setPassed(_ => passed)
          setProgress(_ => passed->Belt.Int.toFloat /. total->Belt.Int.toFloat)
        }
      }
    , 1 * 1000)
    Some(_ => id->clearTimeout)
  }, (passed, total, paused))

  let onClick = (m, _) => {
    if Notification.permission == #default {
      let _ = Notification.requestPermission()
    }
    m->switchToMode
  }

  let title = switch mode {
  | Work => "Keep working!"
  | ShortBreak => "Drink some water!"
  | LongBreak => "Walk around!"
  | Idle => "Please press any button!"
  }

  let buttonForMode = m =>
    <Button disabled=paused onClick={m->onClick} class=m text={m->toString} />

  <div className="nes-container with-title is-centered">
    <p className="title"> {title->string} </p>
    <TimeDisplay mode remaining={total - passed} />
    <Progress value=progress mode />
    {Work->buttonForMode}
    {ShortBreak->buttonForMode}
    {LongBreak->buttonForMode}
    <Button
      disabled={mode == Idle}
      onClick={_ => setPaused(p => !p)}
      class=Idle // Abuse. Pause has nothing to do with Idle
      text={paused ? "Resume" : "Pause"}
    />
    <History history />
  </div>
}
