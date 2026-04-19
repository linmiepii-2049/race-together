'use strict';

const test = require('node:test');
const assert = require('node:assert');
const WebSocket = require('ws');
const {
  startOnEphemeralPort,
  CMD,
  MAX_PER_LOBBY,
  STR_LOBBY_FULL,
} = require('./server.js');

function waitOpen(ws) {
  return new Promise((resolve, reject) => {
    ws.once('open', resolve);
    ws.once('error', reject);
  });
}

function readUntilJoin(ws) {
  return new Promise((resolve, reject) => {
    const onMsg = (raw) => {
      try {
        const m = JSON.parse(String(raw));
        if (m.type === CMD.JOIN) {
          ws.off('message', onMsg);
          resolve(m.data);
        }
      } catch (e) {
        reject(e);
      }
    };
    ws.on('message', onMsg);
  });
}

test('host receives 6-char room code on create', async () => {
  const { port, close } = await startOnEphemeralPort();
  const url = `ws://127.0.0.1:${port}`;
  const host = new WebSocket(url);
  const codePromise = readUntilJoin(host);
  try {
    await waitOpen(host);
    host.send(JSON.stringify({ type: CMD.JOIN, id: 1, data: '' }));
    const code = await codePromise;
    assert.strictEqual(code.length, 6);
  } finally {
    host.terminate();
    await close();
  }
});

test('second peer can join existing room code', async () => {
  const { port, close } = await startOnEphemeralPort();
  const url = `ws://127.0.0.1:${port}`;
  const host = new WebSocket(url);
  const hostCodePromise = readUntilJoin(host);
  let guest = null;
  try {
    await waitOpen(host);
    host.send(JSON.stringify({ type: CMD.JOIN, id: 1, data: '' }));
    const code = await hostCodePromise;
    guest = new WebSocket(url);
    const guestCodePromise = readUntilJoin(guest);
    await waitOpen(guest);
    guest.send(JSON.stringify({ type: CMD.JOIN, id: 1, data: code }));
    const guestCode = await guestCodePromise;
    assert.strictEqual(guestCode, code);
  } finally {
    if (guest) {
      guest.terminate();
    }
    host.terminate();
    await close();
  }
});

test('joinLobby throws when lobby already has max peers', () => {
  const { joinLobby, Peer } = require('./server.js');
  const lobbies = new Map();
  const mesh = false;
  const fakeWs = { send: () => {}, close: () => {} };

  const host = new Peer(100, fakeWs);
  joinLobby(host, '', mesh, lobbies);
  const code = host.lobby;
  assert.strictEqual(code.length, 6);

  for (let i = 1; i < MAX_PER_LOBBY; i += 1) {
    const p = new Peer(100 + i, fakeWs);
    joinLobby(p, code, mesh, lobbies);
  }
  assert.strictEqual(lobbies.get(code).peers.length, MAX_PER_LOBBY);

  const overflow = new Peer(99999, fakeWs);
  assert.throws(
    () => joinLobby(overflow, code, mesh, lobbies),
    (e) => e.message === STR_LOBBY_FULL,
  );
});
