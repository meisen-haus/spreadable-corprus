#!/usr/bin/env node
/**
 * Builds corprus_plague_dialogue.omwaddon:
 *   1× Journal DIAL (cp_carrier) with INFO entries at stages 10 and 100
 *   1× Topic DIAL (strange nightmare) with INFOs for named NPCs (ONAM),
 *       Ashlander faction (FNAM), and Wise Woman classes (CNAM).
 *
 * All topic INFOs form a single PNAM/NNAM chain. Evaluation order: ONAM
 * (most specific) → FNAM → CNAM (broadest). Journal cp_carrier >= 10 gates
 * every entry; cured variants (Sleepers, Sixth House, Wise Woman) require >= 100.
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
  'The figure watched, approving.';

const JOURNAL_CURE_STAGE = 100;
const JOURNAL_CURE_TEXT =
  'Dagoth Ur\'s curse has been lifted. I am no longer his Divine Disease carrier, but at what cost to Vvardenfell?';

// Vanilla: Sleepers Awake begins after returning the Dwemer puzzle box.
const ANTIBOLIS_QUEST_ID = 'A1_2_AntabolisInformant';
const ANTIBOLIS_PUZZLE_BOX_STAGE = 10;

const DIAL_ID = 'strange nightmare';

// OpenMW ESM::DialogueCondition::Function_Choice = 50
const FUNCTION_CHOICE = 50;

const CHOICE_SHARMAT = 1;
const CHOICE_WHAT_CAN_I_DO = 2;

// ---------------------------------------------------------------------------
// Named NPC responses (ONAM) — one INFO each, evaluated first (most specific)
// ---------------------------------------------------------------------------
const NAMED_NPC_INFOS = [
  {
    id: 'CP_SN_CAIUS',
    filter: { type: 'actor', value: 'caius cosades' },
    text:
      'Strange dreams? That\'s troubling. Dagoth Ur\'s influence reaches further than we thought. ' +
      'Don\'t put stock in these visions, but don\'t ignore them either. I\'ll look into it. ' +
      'In the meantime, keep your wits about you.',
    conditions: [{ type: 'journal', value: JOURNAL_NIGHTMARE_STAGE }],
    resultScript: 'Goodbye',
  },
  {
    id: 'CP_SN_MEHRA',
    filter: { type: 'actor', value: 'mehra milo' },
    text:
      'Dreams sent by the Sharmat are not uncommon among those he has touched. ' +
      'The Temple would dismiss such things, but the Ashlanders know more of dream-sendings than we do. ' +
      'Seek out one of their Wise Women if you would understand what has taken hold of you.',
    conditions: [{ type: 'journal', value: JOURNAL_NIGHTMARE_STAGE }],
    resultScript: 'Goodbye',
  },
  {
    id: 'CP_SN_HASSOUR',
    filter: { type: 'actor', value: 'hassour zainsubani' },
    text:
      'A dream of golden masks and ash? That is no ordinary vision. Among my people, the Wise Women are the ' +
      'keepers of dream-lore. They read the sendings of the ancestors and the warnings of the land. ' +
      'If this dream came unbidden, a Wise Woman may know its meaning. Seek one in the camps.',
    conditions: [{ type: 'journal', value: JOURNAL_NIGHTMARE_STAGE }],
    resultScript: 'Goodbye',
  },
];

// Sleepers Awake victims (UESP: Morrowind:Sleepers_Awake) — ONAM, not Sixth House faction.
// Same 15 record IDs as scripts/corprus_plague/config.lua (sleeperAndHouseNpcIds); keep in sync.
const SLEEPER_NPC_IDS = [
  'alvura othrenim',
  'assi serimilk',
  'daynasa telandas',
  'dralas gilu',
  'drarayne girith',
  'dravasa andrethi',
  'endris dilmyn',
  'eralane hledas',
  'llandras belaal',
  'neldris llervu',
  'nelmil hler',
  'rararyn radarys',
  'relur faryon',
  'vireveri darethran',
  'vivyne andrano',
];

const SLEEPER_CULT_TEXT =
  'The vessel approaches, and we breathe deep, for he is with us even now.';

const SLEEPER_CURED_TEXT =
  'Strange nightmare? I don\'t know anything about such things. That sounds awful. ' +
  'I hope it passes.';

function sleeperInfoId(recordId, cured) {
  const slug = recordId.split(' ')[0].slice(0, 4).toUpperCase();
  return cured ? `CP_SN_SL_${slug}_C` : `CP_SN_SL_${slug}`;
}

const SLEEPER_NIGHTMARE_CONDITIONS = [
  { type: 'journal', journalId: JOURNAL_ID, value: JOURNAL_NIGHTMARE_STAGE },
  { type: 'journal', journalId: ANTIBOLIS_QUEST_ID, value: ANTIBOLIS_PUZZLE_BOX_STAGE },
];

const SLEEPER_CURED_CONDITIONS = [
  { type: 'journal', journalId: JOURNAL_ID, value: JOURNAL_CURE_STAGE },
  { type: 'journal', journalId: ANTIBOLIS_QUEST_ID, value: ANTIBOLIS_PUZZLE_BOX_STAGE },
];

const SLEEPER_NPC_INFOS = SLEEPER_NPC_IDS.flatMap((recordId) => [
  {
    id: sleeperInfoId(recordId, true),
    filter: { type: 'actor', value: recordId },
    text: SLEEPER_CURED_TEXT,
    conditions: SLEEPER_CURED_CONDITIONS,
    resultScript: 'Goodbye',
  },
  {
    id: sleeperInfoId(recordId, false),
    filter: { type: 'actor', value: recordId },
    text: SLEEPER_CULT_TEXT,
    conditions: SLEEPER_NIGHTMARE_CONDITIONS,
    resultScript: 'Goodbye',
  },
]);

// ---------------------------------------------------------------------------
// Ashlander faction response (FNAM) — one INFO, evaluated after ONAM
// ---------------------------------------------------------------------------
const FACTION_INFOS = [
  {
    id: 'CP_SN_ASHL',
    filter: { type: 'faction', value: 'ashlander' },
    text:
      'You dream of ash and golden masks? This is not a matter for warriors. ' +
      'Speak to a Wise Woman. They are the ones who understand the sendings.',
    conditions: [{ type: 'journal', value: JOURNAL_NIGHTMARE_STAGE }],
    resultScript: 'Goodbye',
  },
  {
    id: 'CP_SN_6H_CURED',
    filter: { type: 'faction', value: 'sixth house' },
    text:
      'Strange nightmare? I don\'t know anything about such things. That sounds awful. ' +
      'I hope it passes.',
    conditions: [{ type: 'journal', value: JOURNAL_CURE_STAGE }],
    resultScript: 'Goodbye',
  },
  {
    id: 'CP_SN_6H',
    filter: { type: 'faction', value: 'sixth house' },
    text:
      'The vessel approaches, and we breathe deep, for he is with us even now.',
    conditions: [{ type: 'journal', value: JOURNAL_NIGHTMARE_STAGE }],
    resultScript: 'Goodbye',
  },
];

// ---------------------------------------------------------------------------
// Wise Woman class responses (CNAM) — choice branches, evaluated last (broadest)
// ---------------------------------------------------------------------------
const WISE_WOMAN_CLASSES = [
  { classId: 'wise woman', infoSuffix: '' },
  { classId: 'wise woman service', infoSuffix: 'S' },
];

const OPENING_TEXT =
  'You have become a tool for the Sharmat. A vessel for his grotesquery. You bring doom to this island.';

const WISE_WOMAN_LINES = [
  {
    id: 'CP_SN_CH1',
    text:
      'The bastard devil of Red Mountain. With his machinations, he has reached a clawed hand beyond the Ghostfence to spread his malice and his plague. And now you are the bringer of this evil.',
    conditions: [{ type: 'choice', value: CHOICE_SHARMAT }],
    resultScript: `Choice, "What can I do?" ${CHOICE_WHAT_CAN_I_DO}`,
  },
  {
    id: 'CP_SN_CH2',
    text:
      'Throw yourself into the sea, and free yourself from his puppetry. Every day you delay, you murder our people.',
    conditions: [{ type: 'choice', value: CHOICE_WHAT_CAN_I_DO }],
    resultScript: 'Goodbye',
  },
  {
    id: 'CP_SN_CURED',
    text:
      'You struck down the devil, and for that, we are grateful. But the scars his plague has left on this land will not heal so easily. Perhaps our doom was the price of your victory. We shall see if it was worth paying.',
    conditions: [{ type: 'journal', value: JOURNAL_CURE_STAGE }],
    resultScript: 'Goodbye',
  },
  {
    id: 'CP_SN_ROOT',
    text: OPENING_TEXT,
    conditions: [{ type: 'journal', value: JOURNAL_NIGHTMARE_STAGE }],
    resultScript: `Choice, "Sharmat?" ${CHOICE_SHARMAT}`,
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

function buildJournalScvr(journalId) {
  // OpenMW SCVR format: {index}4JX{comparison}{variable}
  // '4' = Journal type, 'J' + 'X' = required indicators, '3' = '>=' (ge)
  return Buffer.from(`04JX3${journalId}`, 'ascii');
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
    const journalId = condition.journalId ?? JOURNAL_ID;
    subrecords.push(subrecord('SCVR', buildJournalScvr(journalId)));
  } else {
    throw new Error(`unknown condition type: ${condition.type}`);
  }
  subrecords.push(subrecord('INTV', intv));
}

const FILTER_SUBRECORD = { actor: 'ONAM', class: 'CNAM', faction: 'FNAM' };

function buildTopicInfo(line, filter, infoId, prevId, nextId) {
  const filterTag = FILTER_SUBRECORD[filter.type];
  if (!filterTag) throw new Error(`unknown filter type: ${filter.type}`);

  const subrecords = [
    subrecord('INAM', zstring(infoId)),
    subrecord('PNAM', zstring(prevId)),
    subrecord('NNAM', zstring(nextId)),
    subrecord('DATA', buildInfoData()),
    subrecord(filterTag, zstring(filter.value)),
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
  Buffer.from('Divine Disease Carrier journal + nightmare dialogue\0', 'ascii').copy(hedr, 40, 0, 256);
  hedr.writeInt32LE(recordCount, 296);

  const masterSize = Buffer.alloc(8);
  masterSize.writeBigInt64LE(0n, 0);

  return record('TES3', [
    subrecord('HEDR', hedr),
    subrecord('MAST', zstring('Morrowind.esm')),
    subrecord('DATA', masterSize),
  ]);
}

// Build flat list of all topic INFOs in evaluation order:
// ONAM (named NPCs + Sleepers) → FNAM → CNAM (Wise Woman classes)
const allTopicInfos = [];

for (const info of NAMED_NPC_INFOS) {
  allTopicInfos.push({ line: info, filter: info.filter, infoId: info.id });
}

for (const info of SLEEPER_NPC_INFOS) {
  allTopicInfos.push({ line: info, filter: info.filter, infoId: info.id });
}

for (const info of FACTION_INFOS) {
  allTopicInfos.push({ line: info, filter: info.filter, infoId: info.id });
}

for (const variant of WISE_WOMAN_CLASSES) {
  for (const line of WISE_WOMAN_LINES) {
    const suffix = variant.infoSuffix;
    allTopicInfos.push({
      line,
      filter: { type: 'class', value: variant.classId },
      infoId: `${line.id}${suffix}`,
    });
  }
}

const JOURNAL_INFO_COUNT = 2;
const CONTENT_RECORDS = 1 + JOURNAL_INFO_COUNT + 1 + allTopicInfos.length;

const records = [buildTes3Header(CONTENT_RECORDS)];

records.push(buildJournalDial());
records.push(buildJournalInfo(JOURNAL_NIGHTMARE_STAGE, JOURNAL_NIGHTMARE_TEXT));
records.push(buildJournalInfo(JOURNAL_CURE_STAGE, JOURNAL_CURE_TEXT));

records.push(buildTopicDial());

for (let i = 0; i < allTopicInfos.length; i++) {
  const { line, filter, infoId } = allTopicInfos[i];
  const prevId = i > 0 ? allTopicInfos[i - 1].infoId : '';
  const nextId = i < allTopicInfos.length - 1 ? allTopicInfos[i + 1].infoId : '';
  records.push(buildTopicInfo(line, filter, infoId, prevId, nextId));
}

const plugin = Buffer.concat(records);
writeFileSync(OUT, plugin);

const text = plugin.toString('binary');
const requiredStrings = [
  ['01500', 'Choice SCVR'],
  [`04JX3${JOURNAL_ID}`, 'cp_carrier Journal SCVR'],
  [`04JX3${ANTIBOLIS_QUEST_ID}`, 'Antabolis Journal SCVR'],
  ['Goodbye', 'Goodbye result script'],
  ['Choice, "Sharmat?"', 'Sharmat choice BNAM'],
  ['Choice, "What can I do?"', 'What can I do choice BNAM'],
  [JOURNAL_ID, 'journal ID'],
  ['caius cosades', 'Caius Cosades ONAM'],
  ['mehra milo', 'Mehra Milo ONAM'],
  ['hassour zainsubani', 'Hassour Zainsubani ONAM'],
  ['ashlander', 'Ashlander FNAM'],
  ['sixth house', 'Sixth House FNAM'],
  ['rararyn radarys', 'Rararyn Radarys ONAM'],
  ['The vessel approaches', 'Sleeper cult line'],
];
for (const [needle, label] of requiredStrings) {
  if (!text.includes(needle)) {
    console.error(`validation failed: missing ${label} (${needle})`);
    process.exit(1);
  }
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
