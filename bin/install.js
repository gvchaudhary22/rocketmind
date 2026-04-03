#!/usr/bin/env node
/**
 * RocketMind SOTA CLI v2.3.0
 * Usage: npx rocketmind [init|sync|promote|help] [--global] [--tool claude|all]
 */

const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const FRAMEWORK_ROOT = path.join(__dirname, '..');
const INSTALL_SCRIPT = path.join(FRAMEWORK_ROOT, 'install.sh');

// Parse CLI args
const args = process.argv.slice(2);
const command = args.find((a) => ['init', 'sync', 'promote', 'help'].includes(a)) || 'init';
const isGlobal = args.includes('--global') || args.includes('-g');
const isNexus = args.includes('nexus') || args.includes('--nexus');
const tool = args.includes('--all')
  ? 'all'
  : args.find((a) => ['claude', 'codex'].includes(a)) || 'claude';

// Colors
const c = {
  green: (s) => `\x1b[32m${s}\x1b[0m`,
  blue: (s) => `\x1b[34m${s}\x1b[0m`,
  yellow: (s) => `\x1b[33m${s}\x1b[0m`,
  red: (s) => `\x1b[31m${s}\x1b[0m`,
  bold: (s) => `\x1b[1m${s}\x1b[0m`,
  dim: (s) => `\x1b[2m${s}\x1b[0m`,
  cyan: (s) => `\x1b[36m${s}\x1b[0m`,
};

console.log(`\n${c.bold('╔══════════════════════════════════════════╗')}`);
console.log(`${c.bold('║        RocketMind SOTA CLI v2.3.0         ║')}`);
console.log(`${c.bold('║      "Nexus" Meta-Orchestrator       ║')}`);
console.log(`${c.bold('╚══════════════════════════════════════════╝')}\n`);

const projectDir = process.cwd();

function runInstaller() {
  const installArgs = [INSTALL_SCRIPT, isGlobal ? '--global' : '--local'];
  if (args.includes('--hooks-only')) installArgs.push('--hooks-only');
  if (args.includes('--skip-verify')) installArgs.push('--skip-verify');
  if (tool === 'all') installArgs.push('--all');
  else installArgs.push('--tool', tool);

  execFileSync('bash', installArgs, { stdio: 'inherit' });
}

/**
 * NEXUS: Initialize logical root
 */
function nexusInit() {
  console.log(c.cyan(`▸ Initializing Nexus Logical Root in ${projectDir}...\n`));

  const nexusConfig = {
    workspace_mode: 'nexus',
    org: path.basename(projectDir),
    last_sync: new Date().toISOString(),
    repos: [],
  };

  fs.writeFileSync(path.join(projectDir, 'rocketmind.nexus.json'), JSON.stringify(nexusConfig, null, 2));
  console.log(`  ${c.green('✓')} rocketmind.nexus.json (Meta-Registry)`);

  const nexusState = `# NEXUS STATE: ${nexusConfig.org}\n\nThis folder is an RocketMind Nexus workspace. Sub-repos are indexed and coordinated by the central Orchestrator.\n`;
  fs.writeFileSync(path.join(projectDir, 'NEXUS-STATE.md'), nexusState);
  console.log(`  ${c.green('✓')} NEXUS-STATE.md (Organizational Memory)`);

  nexusSync();
}

/**
 * NEXUS: Auto-discover sub-repos
 */
function nexusSync() {
  console.log(c.cyan(`\n▸ Syncing Nexus Workspace (Auto-Discovery)...\n`));

  const nexusPath = path.join(projectDir, 'rocketmind.nexus.json');
  if (!fs.existsSync(nexusPath)) {
    console.error(c.yellow('  ⚠️  No rocketmind.nexus.json found. Run "rocketmind nexus init" first.'));
    return;
  }

  const nexus = JSON.parse(fs.readFileSync(nexusPath, 'utf8'));
  const entries = fs.readdirSync(projectDir, { withFileTypes: true });

  nexus.repos = [];

  for (const entry of entries) {
    if (entry.isDirectory() && entry.name !== 'node_modules' && !entry.name.startsWith('.')) {
      const repoPath = path.join(projectDir, entry.name);
      const rocketmindConfig = path.join(repoPath, 'rocketmind.config.json');
      const gitDir = path.join(repoPath, '.git');

      if (fs.existsSync(rocketmindConfig) || fs.existsSync(gitDir)) {
        nexus.repos.push({
          name: entry.name,
          path: `./${entry.name}`,
          rocketmind_aware: fs.existsSync(rocketmindConfig),
        });
        console.log(
          `  ${c.green('✓')} Discovered Repo: ${c.bold(entry.name)} ${fs.existsSync(rocketmindConfig) ? '(RocketMind-Aware)' : '(Legacy)'}`
        );
      }
    }
  }

  nexus.last_sync = new Date().toISOString();
  fs.writeFileSync(nexusPath, JSON.stringify(nexus, null, 2));
  console.log(
    c.green(`\n  ✅ Nexus Workspace Sync Complete (${nexus.repos.length} repos indexed)`)
  );
}

/**
 * KNOWLEDGE PROPAGATION: Promote local patterns to core
 */
function handlePromote() {
  console.log(c.cyan(`\n▸ Scouting for Promotion Candidates in ${projectDir}...\n`));

  const localRocketMind = path.join(projectDir, '.rocketmind');
  if (!fs.existsSync(localRocketMind)) {
    console.error(c.yellow('  ⚠️  No .rocketmind folder found in current directory.'));
    return;
  }

  let corePath = null;
  const nexusPath = path.join(projectDir, '..', 'rocketmind.nexus.json');
  if (fs.existsSync(nexusPath)) {
    const nexus = JSON.parse(fs.readFileSync(nexusPath, 'utf8'));
    const rocketmindRepo = nexus.repos.find((r) => r.name === 'rocketmind');
    if (rocketmindRepo) corePath = path.resolve(projectDir, '..', rocketmindRepo.path);
  }

  if (!corePath) {
    const relativeCore = path.join(projectDir, '..', 'rocketmind');
    if (fs.existsSync(relativeCore)) corePath = relativeCore;
  }

  if (!corePath) {
    console.error(c.red('  ❌ Could not locate RocketMind Core source repo. Propagation aborted.'));
    return;
  }

  console.log(`${c.dim('  Core found at:')} ${corePath}\n`);

  const subdirs = ['agents', 'skills'];
  let count = 0;

  for (const dir of subdirs) {
    const localDir = path.join(localRocketMind, dir);
    if (!fs.existsSync(localDir)) continue;

    const files = fs.readdirSync(localDir);
    for (const file of files) {
      if (!file.endsWith('.md')) continue;
      const content = fs.readFileSync(path.join(localDir, file), 'utf8');

      if (content.includes('promotion_candidate: true')) {
        console.log(`  ${c.yellow('⭐')} Found Candidate: ${c.bold(file)} (${dir})`);
        const dest = path.join(corePath, dir, file);
        if (fs.existsSync(dest)) {
          console.log(`     ${c.dim('⤷ Skipped: Already exists in core.')}`);
        } else {
          fs.copyFileSync(path.join(localDir, file), dest);
          console.log(`     ${c.green('✅ Promoted to core!')}`);
          count++;
        }
      }
    }
  }

  if (count === 0) {
    console.log(c.dim('  No new candidates found for promotion.'));
  } else {
    console.log(c.green(`\n  ✨ Successfully promoted ${count} patterns to RocketMind Core!`));
  }
}

// Run
try {
  if (isNexus || args.includes('nexus')) {
    if (command === 'init' || args.includes('init')) nexusInit();
    else if (command === 'sync' || args.includes('sync')) nexusSync();
    else console.log('Usage: rocketmind nexus [init|sync]');
  } else if (command === 'promote') {
    handlePromote();
  } else if (command === 'help') {
    console.log(
      `Commands:\n  init    - delegate to install.sh for local project setup\n  nexus   - init/sync multi-repo workspace\n  promote - push local patterns to core\n  help    - show this help`
    );
  } else {
    console.log(
      c.yellow(`\n▸ Delegating install to ${path.relative(projectDir, INSTALL_SCRIPT)}...\n`)
    );
    runInstaller();
  }
} catch (err) {
  console.error(`\n${c.red('❌ Command failed:')} ${err.message}`);
  process.exit(1);
}
