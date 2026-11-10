import { spawn } from "node:child_process"
import { homedir } from "node:os"
import { join } from "node:path"
import { Plugin } from "@opencode/plugin/tui"

const script = join(homedir(), ".claude", "hooks", "zellij_attn.py")

export default Plugin.define({
  id: "irving.zellij-attn",
  setup(context) {
    if (!process.env.ZELLIJ_PANE_ID) return

    const mark = (state: "on" | "off") => spawn("python", ["-I", script, state], { stdio: "ignore" })
    const route = context.ui.router.current
    const viewedRoot = () => {
      const current = route()
      return current.type === "session" ? context.data.session.root(current.sessionID) : undefined
    }
    const isViewedRoot = (sessionID: string) => sessionID === viewedRoot()
    const inViewedFamily = (sessionID: string) => context.data.session.root(sessionID) === viewedRoot()

    const stops = [
      context.data.on("session.execution.started", (evt) => isViewedRoot(evt.data.sessionID) && mark("off")),
      context.data.on("session.execution.interrupted", (evt) => isViewedRoot(evt.data.sessionID) && mark("off")),
      context.data.on("session.execution.succeeded", (evt) => isViewedRoot(evt.data.sessionID) && mark("on")),
      context.data.on("session.execution.failed", (evt) => isViewedRoot(evt.data.sessionID) && mark("on")),
      context.data.on("permission.asked", (evt) => inViewedFamily(evt.data.sessionID) && mark("on")),
      context.data.on("form.created", (evt) => inViewedFamily(evt.data.form.sessionID) && mark("on")),
      context.data.on("permission.replied", (evt) => inViewedFamily(evt.data.sessionID) && mark("off")),
      context.data.on("form.replied", (evt) => inViewedFamily(evt.data.sessionID) && mark("off")),
      context.data.on("form.cancelled", (evt) => inViewedFamily(evt.data.sessionID) && mark("off")),
    ]
    return () => stops.forEach((stop) => stop())
  },
})
