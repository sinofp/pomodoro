type permission = [#default | #granted | #denied]

@val @scope("Notification")
external permission: permission = "permission"

@val @scope("Notification")
external requestPermission: unit => promise<permission> = "requestPermission"

module ServiceWorkerRegistration = {
  type t

  @val @scope("navigator.serviceWorker")
  external register: string => promise<t> = "register"

  @val @scope("navigator.serviceWorker")
  external ready: promise<t> = "ready"

  @send external showNotification: (t, string) => promise<unit> = "showNotification"
}

let make = title => {
  open Js.Promise2
  open ServiceWorkerRegistration
  let _ = ready->then(registration => registration->showNotification(title))
}
