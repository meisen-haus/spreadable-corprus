#!/usr/bin/env node
/**
 * Builds corprus_plague_dialogue.omwaddon (1× GLOB + 1× DIAL + 12× INFO (6 per class × 2 classes)).
 * Single topic "strange nightmare": Choice branches + global-staged fallbacks + Goodbye.
 * See dialogue/WISE_WOMAN_IMPLEMENTATION_PLAN.md
 */
import { writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const OUT = join(__dirname, '..', 'corprus_plague_dialogue.omwaddon');

const GLOBAL = 'cp_firstrest_dream';
const DIAL_ID = 'strange nightmare';

const WISE_WOMAN_CLASSES = [
  { classId: 'wise woman', infoSuffix: '' },
  { classId: 'wise woman service', infoSuffix: 'S' },
];

// OpenMW ESM::DialogueCondition::Function_Choice = 49
const FUNCTION_CHOICE = 49;

// Non-zero choice indices so that the uninitialized Function_Choice default (0)
// does not collide with any choice condition — ROOT (no choice filter) matches first.
const CHOICE_SHARMAT = 1;
const CHOICE_WHAT_CAN_I_DO = 2;

// Filter order (first match wins): CH2, CH1, G3, G2, REPEAT, ROOT.
const OPENING_TEXT =
  'You have become a tool for the devil of Red Mountain. A vessel for his grotesquery. You bring doom to this island.';

const INFO_LINES = [
  {
    id: 'CP_SN_CH2',
    prevId: '',
    nextId: 'CP_SN_CH1',
    text:
      'Throw yourself into the sea, and free yourself from his puppetry. Every day you delay, you murder our people.',
    conditions: [
      { type: 'global', operator: '0', value: 2 },
      { type: 'choice', value: CHOICE_WHAT_CAN_I_DO },
    ],
    resultScript: `set ${GLOBAL} to 4\nGoodbye`,
  },
  {
    id: 'CP_SN_CH1',
    prevId: 'CP_SN_CH2',
    nextId: 'CP_SN_G3',
    text:
      'The bastard devil of Red Mountain. With his machinations, he has reached a clawed hand beyond the Ghostfence to spread his malice and his plague. And now you are the bringer of this evil.',
    conditions: [
      { type: 'global', operator: '0', value: 1 },
      { type: 'choice', value: CHOICE_SHARMAT },
    ],
    resultScript: `set ${GLOBAL} to 2\nChoice "What can I do?" ${CHOICE_WHAT_CAN_I_DO}`,
  },
  {
    id: 'CP_SN_G3',
    prevId: 'CP_SN_CH1',
    nextId: 'CP_SN_G2',
    text:
      'Throw yourself into the sea, and free yourself from his puppetry. Every day you delay, you murder our people.',
    conditions: [{ type: 'global', operator: '0', value: 3 }],
    resultScript: `set ${GLOBAL} to 4\nGoodbye`,
  },
  {
    id: 'CP_SN_G2',
    prevId: 'CP_SN_G3',
    nextId: 'CP_SN_REPEAT',
    text:
      'The bastard devil of Red Mountain. With his machinations, he has reached a clawed hand beyond the Ghostfence to spread his malice and his plague. And now you are the bringer of this evil.',
    conditions: [{ type: 'global', operator: '0', value: 2 }],
    resultScript: `Choice "What can I do?" ${CHOICE_WHAT_CAN_I_DO}`,
  },
  {
    id: 'CP_SN_REPEAT',
    prevId: 'CP_SN_G2',
    nextId: 'CP_SN_ROOT',
    text: OPENING_TEXT,
    conditions: [{ type: 'global', operator: '0', value: 4 }],
    resultScript: `set ${GLOBAL} to 1\nChoice "Sharmat?" ${CHOICE_SHARMAT}`,
  },
  {
    id: 'CP_SN_ROOT',
    prevId: 'CP_SN_REPEAT',
    nextId: '',
    // Avoid bare "Sharmat" — keyword search can turn it into a topic link and steal clicks.
    text: OPENING_TEXT,
    conditions: [{ type: 'global', operator: '0', value: 1 }],
    resultScript: `Choice "Sharmat?" ${CHOICE_SHARMAT}`,
  },
];

function subrecord(type, data) {
  const payload = Buffer.isBuffer(data) ? data : Buffer.from(data, 'utf8');
  const header = Buffer.alloc(8);
  header.write(type, 0, 4, 'ascii');
  header.writeInt32LE(payload.length, 4);
  return Buffer.concat([header, payload]);
}

function record(type, subrecords) {
  const body = Buffer.concat(subrecords);
  const header = Buffer.alloc(16);
  header.write(type, 0, 4, 'ascii');
  header.writeInt32LE(body.length, 4);
  header.writeInt32LE(0, 8);
  header.writeInt32LE(0, 12);
  return Buffer.concat([header, body]);
}

function zstring(str) {
  return Buffer.from(`${str}\0`, 'utf8');
}

function buildGlobalShortScvr(operatorDigit) {
  return Buffer.concat([
    Buffer.from('02sX', 'ascii'),
    Buffer.from(operatorDigit, 'ascii'),
    Buffer.from(GLOBAL, 'ascii'),
  ]);
}

function buildChoiceScvr() {
  const fn = String(FUNCTION_CHOICE).padStart(2, '0');
  return Buffer.from(`01${fn}0`, 'ascii');
}

function buildInfoData() {
  const buf = Buffer.alloc(12);
  buf.writeUInt8(0, 0);
  buf.writeInt32LE(0, 4);
  buf.writeInt8(-1, 8);
  buf.writeInt8(-1, 9);
  buf.writeInt8(-1, 10);
  buf.writeUInt8(0, 11);
  return buf;
}

function pushCondition(subrecords, condition) {
  const intv = Buffer.alloc(4);
  intv.writeUInt32LE(condition.value, 0);
  if (condition.type === 'choice') {
    subrecords.push(subrecord('SCVR', buildChoiceScvr()));
  } else if (condition.type === 'global') {
    subrecords.push(subrecord('SCVR', buildGlobalShortScvr(condition.operator)));
  } else {
    throw new Error(`unknown condition type: ${condition.type}`);
  }
  subrecords.push(subrecord('INTV', intv));
}

function buildInfo(line, classId, infoId, prevId, nextId) {
  const subrecords = [
    subrecord('INAM', zstring(infoId)),
    subrecord('PNAM', zstring(prevId)),
    subrecord('NNAM', zstring(nextId)),
    subrecord('DATA', buildInfoData()),
    subrecord('CNAM', zstring(classId)),
    subrecord('NAME', zstring(line.text)),
  ];

  for (const condition of line.conditions) {
    pushCondition(subrecords, condition);
  }

  if (line.resultScript) {
    subrecords.push(subrecord('BNAM', zstring(line.resultScript)));
  }

  return record('INFO', subrecords);
}

function buildGlob() {
  const fltv = Buffer.alloc(4);
  fltv.writeFloatLE(0, 0);
  return record('GLOB', [
    subrecord('NAME', zstring(GLOBAL)),
    subrecord('FNAM', Buffer.from('s', 'ascii')),
    subrecord('FLTV', fltv),
  ]);
}

function buildDial() {
  const data = Buffer.from([0]);
  return record('DIAL', [subrecord('NAME', zstring(DIAL_ID)), subrecord('DATA', data)]);
}

function buildTes3Header(recordCount) {
  const hedr = Buffer.alloc(300);
  hedr.writeFloatLE(1.2, 0);
  hedr.writeInt32LE(1, 4);
  Buffer.from('Spreadable Corprus\0', 'ascii').copy(hedr, 8, 0, 32);
  Buffer.from('Wise Woman topic dialogue for first-rest nightmare\0', 'ascii').copy(hedr, 40, 0, 256);
  hedr.writeInt32LE(recordCount, 296);

  const masterSize = Buffer.alloc(8);
  masterSize.writeBigInt64LE(0n, 0);

  return record('TES3', [
    subrecord('HEDR', hedr),
    subrecord('MAST', zstring('Morrowind.esm')),
    subrecord('DATA', masterSize),
  ]);
}

const INFO_PER_CLASS = INFO_LINES.length;
const CONTENT_RECORDS = 1 + 1 + INFO_PER_CLASS * WISE_WOMAN_CLASSES.length;

const records = [buildTes3Header(CONTENT_RECORDS), buildDial()];
for (const variant of WISE_WOMAN_CLASSES) {
  for (const line of INFO_LINES) {
    const suffix = variant.infoSuffix;
    const infoId = `${line.id}${suffix}`;
    const prevId = line.prevId ? `${line.prevId}${suffix}` : '';
    const nextId = line.nextId ? `${line.nextId}${suffix}` : '';
    records.push(buildInfo(line, variant.classId, infoId, prevId, nextId));
  }
}
records.push(buildGlob());

const plugin = Buffer.concat(records);
writeFileSync(OUT, plugin);

const text = plugin.toString('binary');
if (!text.includes('02sX0cp_firstrest_dream')) {
  console.error('validation failed: missing global SCVR');
  process.exit(1);
}
if (!text.includes('01490')) {
  console.error('validation failed: missing Choice SCVR (01490)');
  process.exit(1);
}
if (!text.includes('Goodbye')) {
  console.error('validation failed: missing Goodbye on final lines');
  process.exit(1);
}
if (!text.includes('Choice "Sharmat?"')) {
  console.error('validation failed: missing Choice BNAM');
  process.exit(1);
}
if (text.includes('Choice "Sharmat?" 1\nChoice "What can I do?"')) {
  console.error('validation failed: root must only offer Sharmat (not What can I do)');
  process.exit(1);
}
if (!text.includes('Choice "Sharmat?" 1')) {
  console.error('validation failed: missing Choice "Sharmat?" 1');
  process.exit(1);
}

let pos = 0;
while (pos < plugin.length - 16) {
  const recType = plugin.toString('ascii', pos, pos + 4);
  const recSize = plugin.readInt32LE(pos + 4);
  if (recSize < 0 || recSize > 100000) {
    break;
  }
  if (recType === 'DIAL') {
    let sub = pos + 16;
    const end = sub + recSize;
    while (sub < end) {
      const subType = plugin.toString('ascii', sub, sub + 4);
      const subSize = plugin.readInt32LE(sub + 4);
      if (subType === 'DATA' && subSize !== 1) {
        console.error('validation failed: DIAL DATA is not 1 byte');
        process.exit(1);
      }
      sub += 8 + subSize;
    }
  }
  pos += 16 + recSize;
}

console.log(`Wrote ${OUT} (${plugin.length} bytes, ${CONTENT_RECORDS} content records)`);
