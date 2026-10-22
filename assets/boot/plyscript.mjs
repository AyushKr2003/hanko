// A small interpreter for Plymouth's script language (the `script` splash
// plugin), so the boot theme (assets/boot/hanko.script) can be run and
// checked without plymouthd: running plymouthd on a live desktop takes the
// console and the display from the compositor.
//
// It follows Plymouth's rules where they matter for a theme:
//   - one name space: `fun f` and `global.f = 1` are the same slot;
//   - a name is looked up in the function's locals, then the globals; an
//     assignment to a name found nowhere makes a local (at the top level,
//     the locals are the globals);
//   - `a.b` and `a["b"]` are the same; a member of nothing, assigned to,
//     makes it a hash; a missing member reads as null;
//   - numbers are doubles; a string plus a number is a string.
// It is stricter than Plymouth in one way: what Plymouth would quietly turn
// into null (calling a null, a method a native object doesn't have, reading
// a name never set, arithmetic on null) throws here, since on a real boot
// those are a broken screen.

export class Hash {
  constructor() { this.map = new Map() }
  get(k) { return this.map.has(String(k)) ? this.map.get(String(k)) : null }
  set(k, v) { this.map.set(String(k), v) }
  has(k) { return this.map.has(String(k)) }
}

export class PlyError extends Error {
  constructor(msg, line) { super(line ? `line ${line}: ${msg}` : msg); this.line = line }
}

// ── Tokens ─────────────────────────────────────────────────────────────
const OPS = ["++", "--", "+=", "-=", "*=", "/=", "%=", "==", "!=", "<=", ">=", "&&", "||",
  "+", "-", "*", "/", "%", "=", "<", ">", "!", "(", ")", "{", "}", "[", "]", ",", ";", ".", "?", ":"]
const KEYWORDS = new Set(["if", "else", "while", "for", "fun", "return", "break", "continue"])

export function tokenize(src) {
  const out = []
  let i = 0, line = 1
  while (i < src.length) {
    const c = src[i]
    if (c === "\n") { line++; i++; continue }
    if (/\s/.test(c)) { i++; continue }
    if (c === "#" || (c === "/" && src[i + 1] === "/")) { while (i < src.length && src[i] !== "\n") i++; continue }
    if (c === "/" && src[i + 1] === "*") {
      const end = src.indexOf("*/", i + 2)
      if (end < 0) throw new PlyError("unterminated comment", line)
      for (let j = i; j < end; j++) if (src[j] === "\n") line++
      i = end + 2; continue
    }
    if (/[0-9]/.test(c) || (c === "." && /[0-9]/.test(src[i + 1]))) {
      const m = /^[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?|^[0-9]+\.?/.exec(src.slice(i))
      out.push({ t: "num", v: parseFloat(m[0]), line }); i += m[0].length; continue
    }
    if (c === '"') {
      let s = "", j = i + 1
      while (j < src.length && src[j] !== '"') {
        if (src[j] === "\\") { const e = src[j + 1]; s += e === "n" ? "\n" : e === "t" ? "\t" : e; j += 2 }
        else { if (src[j] === "\n") line++; s += src[j++] }
      }
      if (j >= src.length) throw new PlyError("unterminated string", line)
      out.push({ t: "str", v: s, line }); i = j + 1; continue
    }
    if (/[A-Za-z_]/.test(c)) {
      const m = /^[A-Za-z_][A-Za-z0-9_]*/.exec(src.slice(i))
      out.push({ t: KEYWORDS.has(m[0]) ? "kw" : "id", v: m[0], line }); i += m[0].length; continue
    }
    const op = OPS.find(o => src.startsWith(o, i))
    if (!op) throw new PlyError(`unexpected character '${c}'`, line)
    out.push({ t: "op", v: op, line }); i += op.length
  }
  out.push({ t: "eof", v: "", line })
  return out
}

// ── Parse ──────────────────────────────────────────────────────────────
export function parse(src) {
  const tk = tokenize(src)
  let p = 0
  const peek = () => tk[p]
  const is = (t, v) => tk[p].t === t && (v === undefined || tk[p].v === v)
  const next = () => tk[p++]
  const want = (t, v) => {
    if (!is(t, v)) throw new PlyError(`expected '${v || t}', found '${tk[p].v || tk[p].t}'`, tk[p].line)
    return next()
  }

  function statement() {
    const line = peek().line
    if (is("op", "{")) { next(); const body = []; while (!is("op", "}")) { if (is("eof")) throw new PlyError("missing '}'", line); body.push(statement()) } next(); return { k: "block", body, line } }
    if (is("op", ";")) { next(); return { k: "block", body: [], line } }
    if (is("kw", "if")) {
      next(); want("op", "("); const cond = expression(); want("op", ")")
      const then = statement(); let other = null
      if (is("kw", "else")) { next(); other = statement() }
      return { k: "if", cond, then, other, line }
    }
    if (is("kw", "while")) { next(); want("op", "("); const cond = expression(); want("op", ")"); return { k: "while", cond, body: statement(), line } }
    if (is("kw", "for")) {
      next(); want("op", "(")
      const init = is("op", ";") ? null : expression(); want("op", ";")
      const cond = is("op", ";") ? null : expression(); want("op", ";")
      const step = is("op", ")") ? null : expression(); want("op", ")")
      return { k: "for", init, cond, step, body: statement(), line }
    }
    if (is("kw", "fun")) {
      next(); const name = want("id").v; want("op", "(")
      const params = []
      while (!is("op", ")")) { params.push(want("id").v); if (is("op", ",")) next() }
      next()
      if (!is("op", "{")) throw new PlyError(`fun ${name} needs a block`, line)
      return { k: "fun", name, params, body: statement(), line }
    }
    if (is("kw", "return")) { next(); const value = is("op", ";") ? null : expression(); want("op", ";"); return { k: "return", value, line } }
    if (is("kw", "break")) { next(); want("op", ";"); return { k: "break", line } }
    if (is("kw", "continue")) { next(); want("op", ";"); return { k: "continue", line } }
    const e = expression(); want("op", ";"); return { k: "exp", e, line }
  }

  function expression() { return assign() }
  function assign() {
    const left = ternary()
    if (is("op") && ["=", "+=", "-=", "*=", "/=", "%="].includes(peek().v)) {
      const op = next().v
      if (!["var", "member", "index"].includes(left.k)) throw new PlyError("cannot assign to this", left.line)
      return { k: "assign", op, target: left, value: assign(), line: left.line }
    }
    return left
  }
  function ternary() {
    const c = binary(0)
    if (is("op", "?")) { next(); const a = assign(); want("op", ":"); const b = assign(); return { k: "cond", c, a, b, line: c.line } }
    return c
  }
  const LEVELS = [["||"], ["&&"], ["==", "!="], ["<", "<=", ">", ">="], ["+", "-"], ["*", "/", "%"]]
  function binary(level) {
    if (level >= LEVELS.length) return unary()
    let left = binary(level + 1)
    while (is("op") && LEVELS[level].includes(peek().v)) {
      const op = next().v
      left = { k: "bin", op, a: left, b: binary(level + 1), line: left.line }
    }
    return left
  }
  function unary() {
    if (is("op", "!") || is("op", "-") || is("op", "+")) { const op = next().v; return { k: "un", op, a: unary(), line: peek().line } }
    if (is("op", "++") || is("op", "--")) { const op = next().v; return { k: "pre", op, a: unary(), line: peek().line } }
    return postfix()
  }
  function postfix() {
    let e = primary()
    for (;;) {
      if (is("op", ".")) { next(); e = { k: "member", o: e, name: want("id").v, line: e.line } }
      else if (is("op", "[")) { next(); const i = expression(); want("op", "]"); e = { k: "index", o: e, i, line: e.line } }
      else if (is("op", "(")) {
        next(); const args = []
        while (!is("op", ")")) { args.push(expression()); if (is("op", ",")) next(); else if (!is("op", ")")) want("op", ",") }
        next(); e = { k: "call", f: e, args, line: e.line }
      }
      else if (is("op", "++") || is("op", "--")) { e = { k: "post", op: next().v, a: e, line: e.line } }
      else return e
    }
  }
  function primary() {
    const t = peek()
    if (t.t === "num") { next(); return { k: "num", v: t.v, line: t.line } }
    if (t.t === "str") { next(); return { k: "str", v: t.v, line: t.line } }
    if (t.t === "id") { next(); return { k: "var", name: t.v, line: t.line } }
    if (is("op", "(")) { next(); const e = expression(); want("op", ")"); return e }
    if (is("op", "[")) {
      next(); const items = []
      while (!is("op", "]")) { items.push(expression()); if (is("op", ",")) next() }
      next()
      // Plymouth's grammar has the empty array only (Omarchy's theme uses
      // `[]`); a filled one is refused here so a theme never relies on it.
      if (items.length) throw new PlyError("an array literal with items: Plymouth only has []", t.line)
      return { k: "hash", line: t.line }
    }
    throw new PlyError(`unexpected '${t.v || t.t}'`, t.line)
  }

  const body = []
  while (!is("eof")) body.push(statement())
  return { k: "block", body, line: 1 }
}

// ── Run ────────────────────────────────────────────────────────────────
class Signal { constructor(kind, value) { this.kind = kind; this.value = value } }

export const isNative = v => v !== null && (typeof v === "object" || typeof v === "function") && !(v instanceof Hash) && !v.ply

export function truthy(v) {
  if (v === null || v === undefined) return false
  if (typeof v === "number") return v !== 0
  if (typeof v === "string") return v.length > 0
  return true
}

export class Interpreter {
  constructor(natives = {}) {
    this.global = new Hash()
    for (const [k, v] of Object.entries(natives)) this.global.set(k, v)
    this.steps = 0
  }

  run(src) {
    this.exec(parse(src), this.global)
  }

  // Call a script function (a callback Plymouth would call).
  call(fn, args = []) {
    if (!fn) return null
    return this.invoke(fn, args, 0)
  }

  lookup(name, local, line) {
    if (name === "global") return { get: () => this.global, set: () => { throw new PlyError("cannot assign global", line) } }
    if (name === "local") return { get: () => local, set: () => { throw new PlyError("cannot assign local", line) } }
    const scope = local.has(name) ? local : this.global.has(name) ? this.global : local
    return {
      get: () => {
        if (!scope.has(name)) throw new PlyError(`'${name}' is read before it is set`, line)
        return scope.get(name)
      },
      peek: () => scope.get(name),
      set: v => scope.set(name, v),
    }
  }

  // An lvalue: { get, set }. A member of nothing that is assigned to (or
  // read through) becomes a hash, as in Plymouth.
  ref(e, local) {
    if (e.k === "var") return this.lookup(e.name, local, e.line)
    if (e.k === "member" || e.k === "index") {
      const key = e.k === "member" ? e.name : this.key(this.eval(e.i, local), e.line)
      const base = this.ref(e.o, local)
      const hashOf = () => {
        let h = base.peek ? base.peek() : base.get()
        if (h === null || h === undefined) { h = new Hash(); base.set(h) }
        if (!(h instanceof Hash)) throw new PlyError(`'.${key}' of something that is not a hash`, e.line)
        return h
      }
      return {
        get: () => {
          const h = base.peek ? base.peek() : base.get()
          if (h === null || h === undefined) return null
          if (isNative(h)) return this.method(h, key, e.line)
          if (!(h instanceof Hash)) throw new PlyError(`'.${key}' of a ${typeof h}`, e.line)
          return h.get(key)
        },
        peek() { return this.get() },
        set: v => hashOf().set(key, v),
      }
    }
    throw new PlyError("not an lvalue", e.line)
  }

  key(v, line) {
    if (typeof v === "number") return String(v)
    if (typeof v === "string") return v
    throw new PlyError("an index that is neither a number nor a string", line)
  }

  method(obj, name, line) {
    const m = obj[name]
    if (typeof m !== "function") throw new PlyError(`${obj.constructor?.name || "object"} has no method ${name}`, line)
    return { native: (...args) => m.apply(obj, args), name }
  }

  num(v, line, what) {
    if (typeof v !== "number" || Number.isNaN(v)) throw new PlyError(`${what} on ${v === null ? "null" : typeof v}`, line)
    return v
  }

  arith(op, a, b, line) {
    if (op === "+" && (typeof a === "string" || typeof b === "string")) {
      const s = x => typeof x === "number" ? (Number.isInteger(x) ? String(x) : String(+x.toFixed(6))) : x === null ? "" : String(x)
      return s(a) + s(b)
    }
    a = this.num(a, line, `'${op}'`); b = this.num(b, line, `'${op}'`)
    switch (op) {
      case "+": return a + b
      case "-": return a - b
      case "*": return a * b
      case "/": return a / b
      case "%": return a % b
    }
  }

  eval(e, local) {
    if (++this.steps > 5e7) throw new PlyError("too many steps (a loop that never ends?)", e.line)
    switch (e.k) {
      case "num": case "str": return e.v
      case "hash": return new Hash()
      case "var": case "member": case "index": return this.ref(e, local).get()
      case "assign": {
        const r = this.ref(e.target, local)
        let v = this.eval(e.value, local)
        if (e.op !== "=") v = this.arith(e.op[0], r.get(), v, e.line)
        r.set(v)
        return v
      }
      case "cond": return truthy(this.eval(e.c, local)) ? this.eval(e.a, local) : this.eval(e.b, local)
      case "un": {
        const v = this.eval(e.a, local)
        if (e.op === "!") return truthy(v) ? 0 : 1
        return e.op === "-" ? -this.num(v, e.line, "'-'") : this.num(v, e.line, "'+'")
      }
      case "pre": case "post": {
        const r = this.ref(e.a, local)
        const old = this.num(r.get(), e.line, `'${e.op}'`)
        const now = e.op === "++" ? old + 1 : old - 1
        r.set(now)
        return e.k === "pre" ? now : old
      }
      case "bin": {
        if (e.op === "&&") return truthy(this.eval(e.a, local)) && truthy(this.eval(e.b, local)) ? 1 : 0
        if (e.op === "||") return truthy(this.eval(e.a, local)) || truthy(this.eval(e.b, local)) ? 1 : 0
        const a = this.eval(e.a, local), b = this.eval(e.b, local)
        if (e.op === "==") return a === b ? 1 : 0
        if (e.op === "!=") return a !== b ? 1 : 0
        if (["<", "<=", ">", ">="].includes(e.op)) {
          if (typeof a === "string" && typeof b === "string") return { "<": a < b, "<=": a <= b, ">": a > b, ">=": a >= b }[e.op] ? 1 : 0
          const x = this.num(a, e.line, `'${e.op}'`), y = this.num(b, e.line, `'${e.op}'`)
          return { "<": x < y, "<=": x <= y, ">": x > y, ">=": x >= y }[e.op] ? 1 : 0
        }
        return this.arith(e.op, a, b, e.line)
      }
      case "call": {
        const f = this.eval(e.f, local)
        const args = e.args.map(a => this.eval(a, local))
        if (f === null) throw new PlyError(`calling nothing (${describe(e.f)})`, e.line)
        return this.invoke(f, args, e.line)
      }
    }
    throw new PlyError(`unknown expression ${e.k}`, e.line)
  }

  invoke(f, args, line) {
    if (f && f.native) return valueOf(f.native(...args))
    if (typeof f === "function") return valueOf(f(...args))
    if (!f || !f.ply) throw new PlyError("calling something that is not a function", line)
    const local = new Hash()
    f.params.forEach((p, i) => local.set(p, args[i] === undefined ? null : args[i]))
    try { this.exec(f.body, local) }
    catch (s) { if (s instanceof Signal && s.kind === "return") return s.value; throw s }
    return null
  }

  exec(s, local) {
    switch (s.k) {
      case "block": for (const x of s.body) this.exec(x, local); return
      case "exp": this.eval(s.e, local); return
      case "if": if (truthy(this.eval(s.cond, local))) this.exec(s.then, local); else if (s.other) this.exec(s.other, local); return
      case "while":
        while (truthy(this.eval(s.cond, local))) {
          try { this.exec(s.body, local) } catch (x) { if (x instanceof Signal && x.kind === "break") break; if (x instanceof Signal && x.kind === "continue") continue; throw x }
        }
        return
      case "for":
        for (s.init && this.eval(s.init, local); !s.cond || truthy(this.eval(s.cond, local)); s.step && this.eval(s.step, local)) {
          try { this.exec(s.body, local) } catch (x) { if (x instanceof Signal && x.kind === "break") break; if (x instanceof Signal && x.kind === "continue") continue; throw x }
        }
        return
      case "fun": this.lookup(s.name, local, s.line).set({ ply: true, name: s.name, params: s.params, body: s.body }); return
      case "return": throw new Signal("return", s.value ? this.eval(s.value, local) : null)
      case "break": throw new Signal("break")
      case "continue": throw new Signal("continue")
    }
    throw new PlyError(`unknown statement ${s.k}`, s.line)
  }
}

const valueOf = v => (v === undefined ? null : typeof v === "boolean" ? (v ? 1 : 0) : v)
function describe(e) {
  if (e.k === "var") return e.name
  if (e.k === "member") return describe(e.o) + "." + e.name
  if (e.k === "index") return describe(e.o) + "[…]"
  return e.k
}
