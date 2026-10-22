// Plymouth's script runtime, mocked, for the boot theme: Window, Image,
// Sprite, Math and Plymouth as the script splash plugin gives them, driving
// plyscript.mjs beside it. No plymouthd, no root, no display: the sprites
// are kept as data and can be drawn to a PNG with ImageMagick.
//
//   node sim.mjs --check THEME_DIR   play a boot through the theme (a wrong
//                                    passphrase, a right one, every size and
//                                    mode); exit 1 on the first error.
//                                    `hanko boot on` runs this before it
//                                    installs anything.
//   node sim.mjs THEME_DIR OUT_DIR   draw the moments of a boot (still,
//                                    typing, deflected, checking, booting)
//                                    as PNGs
//   node sim.mjs --sheet THEME OUT [MOMENT]  four moments on one sheet
//                                    (hanko boot preview), or one moment
//                                    (asked | typing | wrong | booting |
//                                    shutdown) at full size
import { readFileSync, existsSync, mkdirSync } from "node:fs"
import { execFileSync } from "node:child_process"
import { join } from "node:path"
import { fileURLToPath } from "node:url"
import { Interpreter, PlyError } from "./plyscript.mjs"

function pngSize(file) {
  const b = readFileSync(file)
  if (b.toString("latin1", 1, 4) !== "PNG") throw new PlyError(`${file} is not a PNG`)
  return { w: b.readUInt32BE(16), h: b.readUInt32BE(20) }
}

const isNum = v => typeof v === "number" && Number.isFinite(v)
const need = (ok, what) => { if (!ok) throw new PlyError(what) }

class Img {
  constructor(src, w, h, text) { this.src = src; this.w = w; this.h = h; this.text = text }
  GetWidth() { return this.w }
  GetHeight() { return this.h }
  Scale(w, h) {
    need(isNum(w) && isNum(h), `Image.Scale(${w}, ${h}): not numbers`)
    need(w >= 1 && h >= 1, `Image.Scale(${w}, ${h}): an empty image`)
    return new Img(this.src, Math.floor(w), Math.floor(h), this.text)
  }
  Rotate() { return this }
}

class Sprt {
  constructor(sim, image) {
    this.sim = sim; this.id = sim.sprites.length; sim.sprites.push(this)
    this.image = null; this.x = 0; this.y = 0; this.z = 0; this.opacity = 1
    if (image !== undefined && image !== null) this.SetImage(image)
  }
  SetImage(image) { need(image instanceof Img, `Sprite.SetImage(${image}): not an image`); this.image = image }
  GetImage() { return this.image }
  SetX(x) { need(isNum(x), `Sprite.SetX(${x})`); this.x = x }
  SetY(y) { need(isNum(y), `Sprite.SetY(${y})`); this.y = y }
  SetZ(z) { need(isNum(z), `Sprite.SetZ(${z})`); this.z = z }
  GetX() { return this.x }
  GetY() { return this.y }
  GetZ() { return this.z }
  SetPosition(x, y, z) {
    need(isNum(x) && isNum(y), `Sprite.SetPosition(${x}, ${y}, ${z})`)
    this.x = x; this.y = y; if (z !== null && z !== undefined) { need(isNum(z), `Sprite.SetPosition z ${z}`); this.z = z }
  }
  SetOpacity(o) { need(isNum(o), `Sprite.SetOpacity(${o}): not a number`); this.opacity = o }
  GetOpacity() { return this.opacity }
}

// `defines` replaces the script's own constants (PRESS, SHOW_NAME…),
// so one theme can be played both ways.
export function boot(themeDir, { mode = "boot", width = 1920, height = 1080, defines = {} } = {}) {
  const sim = { sprites: [], callbacks: {}, bg: [0, 0, 0], frame: 0, width, height, log: [] }
  const Image = file => {
    need(typeof file === "string", `Image(${file})`)
    const path = join(themeDir, file)
    need(existsSync(path), `Image("${file}"): no such file in the theme`)
    const { w, h } = pngSize(path)
    return new Img(path, w, h)
  }
  Image.Text = (text, r = 1, g = 1, b = 1) => {
    need(typeof text === "string", `Image.Text(${text})`)
    for (const c of [r, g, b]) need(isNum(c) && c >= 0 && c <= 1, `Image.Text colour ${c}`)
    return new Img(null, Math.max(1, text.length * 8), 16, { text, r, g, b })
  }
  const Sprite = image => new Sprt(sim, image)
  const colour = which => (r, g, b) => {
    for (const c of [r, g, b]) need(isNum(c) && c >= 0 && c <= 1.0001, `Window.${which}(${r}, ${g}, ${b})`)
    if (which === "SetBackgroundTopColor") sim.bg = [r, g, b]
  }
  const Window = {
    GetWidth: () => sim.width, GetHeight: () => sim.height, GetX: () => 0, GetY: () => 0,
    SetBackgroundTopColor: colour("SetBackgroundTopColor"), SetBackgroundBottomColor: colour("SetBackgroundBottomColor"),
  }
  const setter = name => fn => { need(fn && fn.ply, `Plymouth.Set${name}Function: not a function`); sim.callbacks[name] = fn }
  const Plymouth = { GetMode: () => mode }
  for (const n of ["Refresh", "BootProgress", "RootMounted", "KeyboardInput", "UpdateStatus", "DisplayNormal", "DisplayPassword",
    "DisplayQuestion", "DisplayMessage", "HideMessage", "Quit", "Message", "SystemUpdate", "DisplayPrompt"])
    Plymouth[`Set${n}Function`] = setter(n)
  const M = {
    Abs: Math.abs, Min: Math.min, Max: Math.max, Clamp: (v, a, b) => Math.min(b, Math.max(a, v)), Pi: Math.PI,
    Cos: Math.cos, Sin: Math.sin, Tan: Math.tan, ATan2: Math.atan2, Sqrt: Math.sqrt, Int: v => { need(isNum(v), `Math.Int(${v})`); return Math.floor(v) },
    Random: () => 0.5,
  }
  const ply = new Interpreter({ Window, Image, Sprite, Plymouth, Math: M })
  let script = readFileSync(join(themeDir, "hanko.script"), "utf8")
  for (const [k, v] of Object.entries(defines)) {
    const re = new RegExp(`^${k} = [^;]*;`, "m")
    if (!re.test(script)) throw new PlyError(`the script has no ${k} to set`)
    script = script.replace(re, `${k} = ${v};`)
  }
  ply.run(script)
  const cb = (name, ...args) => ply.call(sim.callbacks[name], args)
  return {
    sim, ply,
    // `n` frames at 50 a second, with Plymouth's clock (`duration`) running
    // unless `held`, as it is behind a locked disk.
    tick(n = 1, { progress, held = false } = {}) {
      for (let i = 0; i < n; i++) {
        sim.frame++
        if (!held && sim.callbacks.BootProgress) cb("BootProgress", sim.frame / 50, progress ?? Math.min(0.9, sim.frame / 1500))
        cb("Refresh")
      }
    },
    password: (bullets, prompt = "Passphrase for /dev/nvme0n1p9") => cb("DisplayPassword", prompt, bullets),
    normal: () => cb("DisplayNormal"),
    message: text => cb("DisplayMessage", text),
    resize(w, h) { sim.width = w; sim.height = h },
    visible: () => sim.sprites.filter(s => s.image && s.opacity > 0.001).sort((a, b) => a.z - b.z || a.id - b.id),
    global: name => ply.global.get(name),
  }
}

// Draw what is on screen now.
export function draw(b, out) {
  const hex = b.sim.bg.map(c => Math.round(c * 255).toString(16).padStart(2, "0")).join("")
  const args = ["-size", `${b.sim.width}x${b.sim.height}`, `xc:#${hex}`]
  for (const s of b.visible()) {
    const img = s.image
    const o = Math.max(0, Math.min(1, s.opacity)).toFixed(3)
    if (img.src) args.push("(", img.src, "-resize", `${img.w}x${img.h}!`, "-channel", "A", "-evaluate", "multiply", o, "+channel", ")")
    else {
      const t = img.text, col = `rgb(${Math.round(t.r * 255)},${Math.round(t.g * 255)},${Math.round(t.b * 255)})`
      args.push("(", "-background", "none", "-fill", col, "-pointsize", "13", `label:${t.text}`, ")")
    }
    args.push("-geometry", `+${Math.round(s.x)}+${Math.round(s.y)}`, "-composite")
  }
  args.push(out)
  execFileSync("magick", args)
  return out
}

// Every path a boot can take through the theme, as plymouthd calls it.
export function check(themeDir) {
  for (const defines of [{}, { PRESS: 0, SHOW_NAME: 0 }]) playAll(themeDir, defines)
}
function playAll(themeDir, defines) {
  for (const [w, h] of [[1920, 1080], [3840, 2160], [1366, 768], [2560, 1600]]) {
    const b = boot(themeDir, { width: w, height: h, defines })
    b.tick(20, { held: true }); b.password(0); b.tick(30, { held: true })
    for (let i = 1; i <= 40; i++) { b.password(i); b.tick(1, { held: true }) }
    for (let i = 39; i >= 0; i--) b.password(i)
    for (let n = 1; n <= 11; n++) {   // more wrong ones than there are hints
      b.password(6); b.normal(); b.tick(5, { held: true }); b.password(0); b.tick(25, { held: true })
    }
    b.password(4); b.normal(); b.tick(10, { held: true }); b.tick(800)          // right: the clock runs again
    b.message("A start job is running"); b.tick(2)
    b.resize(w / 2, h / 2); b.tick(2); b.resize(w, h); b.tick(2)               // a display that comes late
    const c = boot(themeDir, { width: w, height: h, defines })
    c.tick(5); c.password(3); c.normal(); c.tick(400, { held: true }); c.tick(20) // no new prompt: taken as open
    const d = boot(themeDir, { width: w, height: h, defines }); d.tick(600)    // no disk to unlock
  }
  for (const mode of ["shutdown", "reboot", "resume", "suspend", "updates", "system-upgrade"]) boot(themeDir, { mode, defines }).tick(80)
}

// One moment, as plymouthd would leave the screen in it.
export function moment(themeDir, key, opts = {}) {
  const b = boot(themeDir, { ...opts, mode: key === "shutdown" ? "shutdown" : "boot" })
  if (key === "shutdown") { b.tick(90); return b }
  b.tick(20, { held: true }); b.password(0); b.tick(60, { held: true })
  if (key === "typing" || key === "wrong") { for (let i = 1; i <= 7; i++) b.password(i); b.tick(2, { held: true }) }
  if (key === "wrong") { b.normal(); b.tick(5, { held: true }); b.password(0); b.tick(3, { held: true }) }
  if (key === "booting") { b.password(6); b.normal(); b.tick(5, { held: true }); b.tick(330) }
  return b
}
export function sheet(themeDir, out, opts = {}) {
  const parts = ["asked", "typing", "wrong", "booting"].map(k => draw(moment(themeDir, k, opts), `${out}.${k}.png`))
  execFileSync("magick", ["(", parts[0], parts[1], "+append", ")", "(", parts[2], parts[3], "+append", ")", "-append", "-resize", "50%", out])
  for (const p of parts) execFileSync("rm", ["-f", p])
  return out
}

if (process.argv[2] === "--sheet") {
  const [theme, out, key] = process.argv.slice(3)
  try { console.log(key ? draw(moment(theme, key), out) : sheet(theme, out)) }
  catch (e) { console.error(`boot theme: ${e.message}`); process.exit(1) }
} else if (process.argv[2] === "--check") {
  try { check(process.argv[3]); console.log("boot theme ok") }
  catch (e) { console.error(`boot theme: ${e.message}`); process.exit(1) }
} else if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const [theme, out] = process.argv.slice(2)
  if (!theme || !out) { console.error("usage: node tests/boot/sim.mjs THEME_DIR OUT_DIR"); process.exit(2) }
  mkdirSync(out, { recursive: true })
  const b = boot(theme)
  const shot = name => console.log(draw(b, join(out, `${name}.png`)))
  b.tick(4); shot("00-black")
  b.tick(14); shot("01-pressing")
  b.tick(10, { held: true }); b.password(0); b.tick(30, { held: true }); shot("02-asked")
  for (let i = 1; i <= 7; i++) { b.password(i); b.tick(3, { held: true }) }
  shot("03-drawing")
  b.normal(); b.tick(20, { held: true }); shot("04-checking")
  b.password(0); b.tick(2, { held: true }); shot("05-deflected")
  b.tick(30, { held: true }); shot("06-after")
  for (let i = 1; i <= 18; i++) { b.password(i); b.tick(1, { held: true }) }
  shot("07-long")
  b.normal(); b.tick(10, { held: true }); b.tick(30); shot("08-booting")
  b.tick(400); shot("09-later")
  b.message("A start job is running for /home"); b.tick(1); shot("10-message")
}
