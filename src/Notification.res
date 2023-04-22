type permission = [#default | #granted | #denied]

@val @scope("Notification")
external permission: permission = "permission"

@val @scope("Notification")
external requestPermission: unit => promise<permission> = "requestPermission"

@val @scope("window")
external focus: unit => unit = "focus"

type t

@new external make': string => t = "Notification"

@set external onClick: (t, _ => unit) => unit = "onclick"

let make = title => {
  let n = title->make'
  n->onClick(_ => focus())
}
