import Quickshell
import Quickshell.Io
import QtQuick

// Runs bash command strings. Every run carries a token and a watchdog, because
// a Process whose binary is missing never emits exited() (a known Quickshell
// gotcha) — the watchdog guarantees `finished` fires exactly once per run.
Scope {
  id: runner
  signal finished(string token, int code, string out)
  property var jobs: ({})

  function run(token, cmd, timeoutMs) {
    var job = jobComponent.createObject(runner, {
      token: token,
      timeoutMs: timeoutMs > 0 ? timeoutMs : 10000,
      cmd: cmd
    })
    jobs[token] = job
    job.start()
  }

  function killAll() {
    for (var t in jobs) if (jobs[t]) jobs[t].abort()
    jobs = ({})
  }

  function forget(token) { delete jobs[token] }

  property Component jobComponent: Component {
    Scope {
      id: job
      property string token
      property string cmd
      property int timeoutMs: 10000
      property bool done: false
      property bool exited: false
      property bool streamed: false
      property int code: 0
      property string out: ""

      function start() { proc.command = ["bash", "-lc", job.cmd]; proc.running = true }
      function settle() { if (exited && streamed) finish(code, out) }
      function finish(c, o) {
        if (done) return
        done = true
        watchdog.stop()
        runner.forget(token)
        runner.finished(token, c, o)
        job.destroy()
      }
      function abort() { done = true; proc.running = false; watchdog.stop(); job.destroy() }

      Process {
        id: proc
        stdout: StdioCollector {
          waitForEnd: true
          onStreamFinished: { job.out = String(text || ""); job.streamed = true; job.settle() }
        }
        onExited: function(exitCode, exitStatus) { job.code = exitCode; job.exited = true; job.settle() }
      }
      Timer {
        id: watchdog
        running: true
        interval: job.timeoutMs
        onTriggered: { proc.running = false; job.finish(124, job.out) }
      }
    }
  }
}
