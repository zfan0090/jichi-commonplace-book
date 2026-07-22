/*
 * simulation.js
 *
 * A lightweight JS port of simulation/adoption_model.py, so the same
 * "does the system tip into wide adoption, or stall?" question can be
 * explored interactively in the browser. Logic mirrors the Python
 * version; parameters are re-tuned slightly for a smaller, canvas-
 * friendly population (140 agents instead of 2000) while preserving
 * the same qualitative dynamics (baseline stalls near the seed level,
 * mandate tips the network, subsidy alone is not sufficient).
 */

(function () {
  "use strict";

  // ---- seeded RNG for reproducible layout/costs ----
  function mulberry32(seed) {
    return function () {
      seed |= 0; seed = (seed + 0x6D2B79F5) | 0;
      let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
      t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
  }
  function gaussian(rng, mean, sd) {
    const u1 = Math.max(rng(), 1e-9), u2 = rng();
    const z = Math.sqrt(-2 * Math.log(u1)) * Math.cos(2 * Math.PI * u2);
    return mean + z * sd;
  }

  const TYPES = [
    { name: "大航司",       key: "airline",      share: 0.02, costMean: 40000, costSd: 8000, benefit: 1200, resistance: 0,     color: "#F5A623" },
    { name: "大货代",       key: "largeFF",      share: 0.08, costMean: 25000, costSd: 6000, benefit: 900,  resistance: 0,     color: "#4ADE80" },
    { name: "小货代",       key: "smallFF",      share: 0.75, costMean: 15000, costSd: 5000, benefit: 250,  resistance: 0,     color: "#5B8DEF" },
    { name: "海关经纪人",   key: "customs",      share: 0.10, costMean: 18000, costSd: 4000, benefit: 400,  resistance: 0,     color: "#C084FC" },
    { name: "现有消息中介", key: "intermediary", share: 0.05, costMean: 20000, costSd: 3000, benefit: 150,  resistance: 35000, color: "#F87171" },
  ];

  const N_AGENTS = 140;
  const N_ROUNDS = 30;
  const NETWORK_SCALE = 300;
  const SEED_FRACTION = 0.02;
  const MANDATE_ROUND = 5;

  function buildPopulation(seed) {
    const rng = mulberry32(seed);
    const agents = [];
    TYPES.forEach((t) => {
      const n = Math.round(t.share * N_AGENTS);
      for (let i = 0; i < n; i++) {
        agents.push({
          type: t.key,
          typeName: t.name,
          color: t.color,
          cost: Math.max(1000, gaussian(rng, t.costMean, t.costSd)),
          benefit: t.benefit,
          resistance: t.resistance,
          adopted: false,
          adoptedRound: -1,
          x: 0, y: 0, // set by layout()
        });
      }
    });
    // seed a couple of innovators (mirrors real early-mover anecdotes in the paper)
    const nSeed = Math.max(1, Math.round(SEED_FRACTION * agents.length));
    const idxRng = mulberry32(seed + 7);
    const used = new Set();
    while (used.size < nSeed) {
      const idx = Math.floor(idxRng() * agents.length);
      if (!used.has(idx)) { used.add(idx); agents[idx].adopted = true; agents[idx].adoptedRound = 0; }
    }
    layout(agents, seed);
    return agents;
  }

  // simple cluster layout: one loose cluster per type, arranged around a circle
  function layout(agents, seed) {
    const rng = mulberry32(seed + 99);
    const W = 640, H = 420, cx = W / 2, cy = H / 2;
    const clusterRadius = 150;
    const byType = {};
    TYPES.forEach((t, i) => (byType[t.key] = i));
    TYPES.forEach((t, i) => {
      const angle = (i / TYPES.length) * Math.PI * 2 - Math.PI / 2;
      const ccx = cx + Math.cos(angle) * clusterRadius;
      const ccy = cy + Math.sin(angle) * clusterRadius * 0.78;
      const members = agents.filter((a) => a.type === t.key);
      members.forEach((a) => {
        const rr = 34 + rng() * 58;
        const aa = rng() * Math.PI * 2;
        a.x = ccx + Math.cos(aa) * rr;
        a.y = ccy + Math.sin(aa) * rr;
      });
    });
  }

  function step(agents, round, scenario, fractionAdopted) {
    if (scenario === "mandate" || scenario === "both") {
      if (round === MANDATE_ROUND) {
        agents.forEach((a) => {
          if (a.type === "airline" || a.type === "largeFF") { a.adopted = true; a.adoptedRound = round; }
        });
      }
    }
    const subsidy = (scenario === "subsidy" || scenario === "both") ? 0.4 : 0.0;

    agents.forEach((a) => {
      if (a.adopted) return;
      let effCost = a.cost;
      if (subsidy > 0 && a.type === "smallFF") effCost *= (1 - subsidy);
      const value = a.benefit * fractionAdopted * NETWORK_SCALE - effCost - a.resistance;
      if (value > 0) { a.adopted = true; a.adoptedRound = round; }
    });
  }

  function fractionOf(agents, typeKey) {
    const members = typeKey ? agents.filter((a) => a.type === typeKey) : agents;
    if (members.length === 0) return 0;
    return members.filter((a) => a.adopted).length / members.length;
  }

  // ---- public API consumed by script.js ----
  window.AdoptionSim = {
    TYPES,
    N_ROUNDS,
    create(seed) { return buildPopulation(seed || 42); },
    step,
    fractionOf,
  };
})();
