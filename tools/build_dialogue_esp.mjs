#!/usr/bin/env node
/**
 * Builds corprus_plague_dialogue.omwaddon:
 *   1× Journal DIAL (cp_carrier) with 1× INFO at stage 10
 *   1× Topic DIAL (strange nightmare) with 6× INFO (3 per Wise Woman class)
 *
 * The journal gates topic visibility: ROOT INFO condition requires Journal cp_carrier >= 10.
 * Choice branching within a single conversation handles the rest.
 *
 * See dialogue/WISE_WOMAN_IMPLEMENTATION_PLAN.md
 */
import { writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const OUT = join(__dirname, '..', 'corprus_plague_dialogue.omwaddon');

const JOURNAL_ID = 'cp_carrier';
const JOURNAL_NIGHTMARE_STAGE = 10;
const JOURNAL_NIGHTMARE_TEXT =
  'I woke from a strange and vivid dream. A tall figure in a golden mask led me down ' +
  'the gangplank at Seyda Neen. I tried to speak, but only ashes poured from my mouth. ' +
  'The figure watched, approving. I should speak to a Wise Woman about this.';

const DIAL_ID = 'strange nightmare';

const WISE_WOMAN_CLASSES = [
  { classId: 'wise woman', infoSuffix: '' },
  { classId: 'wise woman service', infoSuffix: 'S' },
];

// OpenMW ESM::DialogueCondition::Function_Choice = 49
const FUNCTION_CHOICE = 49;
// OpenMW ESM::DialogueCondition::Function_Journal = 50
const FUNCTION_JOURNAL = 50;

// Non-zero choice indices — uninitialized Function_Choice (0) must not match.
const CHOICE_SHARMAT = 1;
const CHOICE_WHAT_CAN_I_DO = 2;

const OPENING_TEXT =
  'You have become a tool for the devil of Red Mountain. A vessel for his grotesquery. You bring doom to this island.';

// File order matters: choice-conditioned INFOs before ROOT so ROOT only matches
// when no choice is active (first topic click). After a choice, CH1/CH2 match first.
const TOPIC_INFO_LINES = [
  {
    id: 'CP_SN_CH1',
    prevId: '',
    nextId: 'CP_SN_CH2',
    text:
      'The bastard devil of Red Mountain. With his machinations, he has reached a clawed hand beyond the Ghostfence to spread his malice and his plague. And now you are the bringer of this evil.',
    conditions: [
      { type: 'choice', value: CHOICE_SHARMAT },
    ],
    resultScript: `Choice "What can I do?" ${CHOICE_WHAT_CAN_I_DO}`,
  },
  {
    id: 'CP_SN_CH2',
    prevId: 'CP_SN_CH1',
    nextId: 'CP_SN_ROOT',
    text:
      'Throw yourself into the sea, and free yourself from his puppetry. Every day you delay, you murder our people.',
    conditions: [
      { type: 'choice', value: CHOICE_WHAT_CAN_I_DO },
    ],
    resultScript: 'Goodbye',
  },
  {
    id: 'CP_SN_ROOT',
    prevId: 'CP_SN_CH2',
    nextId: '',
    text: OPENING_TEXT,
    conditions: [
      { type: 'journal', value: JOURNAL_NIGHTMARE_STAGE },
    ],
    resultScript: `Choice "Sharmat?" ${CHOICE_SHARMAT} "What can I do?" ${CHOICE_WHAT_CAN_I_DO}`,
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

function buildJournalScvr() {
  const fn = String(FUNCTION_JOURNAL).padStart(2, '0');
  // Comparison operator 3 = '>=' (ge)
  return Buffer.from(`01${fn}3`, 'ascii');
}

function buildChoiceScvr() {
  const fn = String(FUNCTION_CHOICE).padStart(2, '0');
  // Comparison operator 0 = '=='
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
  intv.writeInt32LE(condition.value, 0);
  if (condition.type === 'choice') {
    subrecords.push(subrecord('SCVR', buildChoiceScvr()));
  } else if (condition.type === 'journal') {
    subrecords.push(subrecord('SCVR', buildJournalScvr()));
  } else {
    throw new Error(`unknown condition type: ${condition.type}`);
  }
  subrecords.push(subrecord('INTV', intv));
}

function buildTopicInfo(line, classId, infoId, prevId, nextId) {
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

function buildJournalInfoData(stage) {
  const buf = Buffer.alloc(12);
  buf.writeUInt8(4, 0);
  buf.writeInt32LE(stage, 4);
  buf.writeInt8(-1, 8);
  buf.writeInt8(-1, 9);
  buf.writeInt8(-1, 10);
  buf.writeUInt8(0, 11);
  return buf;
}

function buildJournalDial() {
  const data = Buffer.from([4]);
  return record('DIAL', [subrecord('NAME', zstring(JOURNAL_ID)), subrecord('DATA', data)]);
}

function buildJournalInfo(stage, text) {
  const infoId = `CP_J_${stage}`;
  return record('INFO', [
    subrecord('INAM', zstring(infoId)),
    subrecord('PNAM', zstring('')),
    subrecord('NNAM', zstring('')),
    subrecord('DATA', buildJournalInfoData(stage)),
    subrecord('NAME', zstring(text)),
    subrecord('QSTN', Buffer.from([1])),
  ]);
}

function buildTopicDial() {
  const data = Buffer.from([0]);
  return record('DIAL', [subrecord('NAME', zstring(DIAL_ID)), subrecord('DATA', data)]);
}

function buildTes3Header(recordCount) {
  const hedr = Buffer.alloc(300);
  hedr.writeFloatLE(1.2, 0);
  hedr.writeInt32LE(1, 4);
  Buffer.from('Spreadable Corprus\0', 'ascii').copy(hedr, 8, 0, 32);
  Buffer.from('Divine Disease Carrier journal + Wise Woman dialogue\0', 'ascii').copy(hedr, 40, 0, 256);
  hedr.writeInt32LE(recordCount, 296);

  const masterSize = Buffer.alloc(8);
  masterSize.writeBigInt64LE(0n, 0);

  return record('TES3', [
    subrecord('HEDR', hedr),
    subrecord('MAST', zstring('Morrowind.esm')),
    subrecord('DATA', masterSize),
  ]);
}

// Content records: 1 journal DIAL + 1 journal INFO + 1 topic DIAL + (3 topic INFOs × 2 classes)
const TOPIC_INFOS_PER_CLASS = TOPIC_INFO_LINES.length;
const CONTENT_RECORDS = 1 + 1 + 1 + TOPIC_INFOS_PER_CLASS * WISE_WOMAN_CLASSES.length;

const records = [buildTes3Header(CONTENT_RECORDS)];

records.push(buildJournalDial());
records.push(buildJournalInfo(JOURNAL_NIGHTMARE_STAGE, JOURNAL_NIGHTMARE_TEXT));

records.push(buildTopicDial());
for (const variant of WISE_WOMAN_CLASSES) {
  for (const line of TOPIC_INFO_LINES) {
    const suffix = variant.infoSuffix;
    const infoId = `${line.id}${suffix}`;
    const prevId = line.prevId ? `${line.prevId}${suffix}` : '';
    const nextId = line.nextId ? `${line.nextId}${suffix}` : '';
    records.push(buildTopicInfo(line, variant.classId, infoId, prevId, nextId));
  }
}

const plugin = Buffer.concat(records);
writeFileSync(OUT, plugin);

const text = plugin.toString('binary');
if (!text.includes('01490')) {
  console.error('validation failed: missing Choice SCVR (01490)');
  process.exit(1);
}
if (!text.includes('01503')) {
  console.error('validation failed: missing Journal SCVR (01503)');
  process.exit(1);
}
if (!text.includes('Goodbye')) {
  console.error('validation failed: missing Goodbye on final line');
  process.exit(1);
}
if (!text.includes('Choice "Sharmat?"')) {
  console.error('validation failed: missing Choice "Sharmat?" BNAM');
  process.exit(1);
}
if (!text.includes('Choice "What can I do?"')) {
  console.error('validation failed: missing Choice "What can I do?" BNAM');
  process.exit(1);
}
if (!text.includes(JOURNAL_ID)) {
  console.error('validation failed: missing journal ID');
  process.exit(1);
}

let pos = 0;
while (pos < plugin.length - 16) {
  const recType = plugin.toString('ascii', pos, pos + 4);
  const recSize = plugin.readInt32LE(pos + 4);
  if (recSize < 0 || recSize > 100000) break;
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
