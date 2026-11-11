// Run with: node --test tests/
// Loads the QML-side JS helper into a sandbox (it is a plain script, not a module).
import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import vm from "node:vm";

const here = new URL(".", import.meta.url);
const ctx = vm.createContext({});
vm.runInContext(readFileSync(new URL("../plugin/HeadsetBattery/headset.js", here), "utf8"), ctx);
const { parseHeadsetControl, lowBatteryStep } = ctx;
const fixture = name => readFileSync(new URL(`fixtures/${name}.json`, here), "utf8");
const plain = o => JSON.parse(JSON.stringify(o)); // strip vm realm prototypes for deepEqual

const NAME = "Logitech G PRO X 2 LIGHTSPEED";

test("online with level", () => {
    assert.deepEqual(plain(parseHeadsetControl(fixture("online"))), { kind: "online", level: 87, device: NAME });
});

test("charging with level", () => {
    assert.deepEqual(plain(parseHeadsetControl(fixture("charging"))), { kind: "charging", level: 64, device: NAME });
});

test("charging without level", () => {
    assert.deepEqual(plain(parseHeadsetControl(fixture("charging-unknown-level"))), { kind: "charging", level: -1, device: NAME });
});

test("offline (BATTERY_UNAVAILABLE)", () => {
    assert.deepEqual(plain(parseHeadsetControl(fixture("offline"))), { kind: "offline", level: -1, device: NAME });
});

test("offline (no battery object, only errors)", () => {
    assert.deepEqual(plain(parseHeadsetControl(fixture("offline-no-battery"))), { kind: "offline", level: -1, device: NAME });
});

test("no device", () => {
    assert.equal(parseHeadsetControl(fixture("no-device")).kind, "nodevice");
});

test("garbage output", () => {
    assert.equal(parseHeadsetControl("Segmentation fault").kind, "error");
    assert.equal(parseHeadsetControl("").kind, "error");
});

test("BATTERY_AVAILABLE with invalid level counts as offline", () => {
    const doc = JSON.stringify({ devices: [{ device: "X", battery: { status: "BATTERY_AVAILABLE", level: -1 } }] });
    assert.equal(parseHeadsetControl(doc).kind, "offline");
});

test("prefers the first device that reports a battery", () => {
    const doc = JSON.stringify({ devices: [{ device: "Wired" }, { device: "Wireless", battery: { status: "BATTERY_AVAILABLE", level: 50 } }] });
    assert.deepEqual(plain(parseHeadsetControl(doc)), { kind: "online", level: 50, device: "Wireless" });
});

// --- notifications ---
const on = level => ({ kind: "online", level });
const W = 20, U = 10;

test("no notification above warning threshold", () => {
    assert.deepEqual(plain(lowBatteryStep(0, on(50), W, U)), { tier: 0, notify: "" });
});

test("warn once, then urgent once, as battery drains", () => {
    let tier = 0;
    const sent = [];
    for (const level of [25, 21, 20, 19, 15, 11, 10, 9, 5, 1]) {
        const r = lowBatteryStep(tier, on(level), W, U);
        tier = r.tier;
        if (r.notify) sent.push(`${r.notify}@${level}`);
    }
    assert.deepEqual(sent, ["warn@20", "urgent@10"]);
});

test("jumping straight below urgent sends only urgent", () => {
    assert.deepEqual(plain(lowBatteryStep(0, on(8), W, U)), { tier: 2, notify: "urgent" });
});

test("charging resets the tier", () => {
    assert.deepEqual(plain(lowBatteryStep(2, { kind: "charging", level: -1 }, W, U)), { tier: 0, notify: "" });
});

test("offline keeps the tier (no re-notify on reconnect at same level)", () => {
    assert.deepEqual(plain(lowBatteryStep(1, { kind: "offline", level: -1 }, W, U)), { tier: 1, notify: "" });
    assert.deepEqual(plain(lowBatteryStep(1, on(19), W, U)), { tier: 1, notify: "" });
});

test("small fluctuation around the threshold does not reset (hysteresis)", () => {
    assert.deepEqual(plain(lowBatteryStep(1, on(23), W, U)), { tier: 1, notify: "" });
    assert.deepEqual(plain(lowBatteryStep(1, on(26), W, U)), { tier: 0, notify: "" });
});

test("urgent threshold above warn is clamped to warn", () => {
    assert.deepEqual(plain(lowBatteryStep(0, on(15), 15, 25)), { tier: 2, notify: "urgent" });
});
