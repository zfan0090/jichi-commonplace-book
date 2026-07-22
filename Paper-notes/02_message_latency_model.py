/* script.js — UI wiring: scroll reveals + the simulation control panel */

(function () {
  "use strict";

  /* ---- scroll reveal ---- */
  const revealEls = document.querySelectorAll(".reveal");
  if ("IntersectionObserver" in window) {
    const io = new IntersectionObserver(
      (entries) => {
        entries.forEach((e) => {
          if (e.isIntersecting) { e.target.classList.add("in"); io.unobserve(e.target); }
        });
      },
      { threshold: 0.08 }
    );
    revealEls.forEach((el) => io.observe(el));
  } else {
    revealEls.forEach((el) => el.classList.add("in"));
  }

  /* ---- simulation wiring ---- */
  const networkCanvas = document.getElementById("networkCanvas");
  const chartCanvas = document.getElementById("chartCanvas");
  if (!networkCanvas || !chartCanvas || !window.AdoptionSim) return;

  const nctx = networkCanvas.getContext("2d");
  const cctx = chartCanvas.getContext("2d");
  const scenarioSel = document.getElementById("scenario");
  const playBtn = document.getElementById("playBtn");
  const resetBtn = document.getElementById("resetBtn");
  const roundLabel = document.getElementById("roundLabel");

  const readouts = {
    overall1: document.getElementById("adoptedPct"),
    overall2: document.getElementById("adoptedPct2"),
    airline: document.getElementById("pctAirline"),
    largeFF: document.getElementById("pctLargeFF"),
    smallFF: document.getElementById("pctSmallFF"),
    customs: document.getElementById("pctCustoms"),
    intermediary: document.getElementById("pctIntermediary"),
  };

  const SEED = 42;
  let agents = window.AdoptionSim.create(SEED);
  let round = 0;
  let history = [];
  let timer = null;

  function pct(x) { return Math.round(x * 100) + "%"; }

  function drawNetwork() {
    const W = networkCanvas.width, H = networkCanvas.height;
    nctx.clearRect(0, 0, W, H);
    nctx.fillStyle = "#0D1526";
    nctx.fillRect(0, 0, W, H);

    agents.forEach((a) => {
      nctx.beginPath();
      nctx.arc(a.x, a.y, 6, 0, Math.PI * 2);
      nctx.fillStyle = a.adopted ? a.color : hexWithAlpha(a.color, 0.28);
      nctx.fill();
      if (a.adopted) {
        nctx.lineWidth = 1.4;
        nctx.strokeStyle = "rgba(237,241,247,0.85)";
        nctx.stroke();
      }
    });
  }

  function hexWithAlpha(hex, alpha) {
    const r = parseInt(hex.slice(1, 3), 16);
    const g = parseInt(hex.slice(3, 5), 16);
    const b = parseInt(hex.slice(5, 7), 16);
    return `rgba(${r},${g},${b},${alpha})`;
  }

  function drawChart() {
    const W = chartCanvas.width, H = chartCanvas.height;
    const padL = 30, padB = 20, padT = 10, padR = 10;
    cctx.clearRect(0, 0, W, H);
    cctx.fillStyle = "#0D1526";
    cctx.fillRect(0, 0, W, H);

    // axes
    cctx.strokeStyle = "#26314A";
    cctx.lineWidth = 1;
    cctx.beginPath();
    cctx.moveTo(padL, padT); cctx.lineTo(padL, H - padB); cctx.lineTo(W - padR, H - padB);
    cctx.stroke();

    cctx.fillStyle = "#5C6A87";
    cctx.font = "10px IBM Plex Mono, monospace";
    cctx.fillText("100%", 2, padT + 8);
    cctx.fillText("0%", 10, H - padB + 3);

    if (history.length < 2) return;
    const maxRound = window.AdoptionSim.N_ROUNDS;
    const plotW = W - padL - padR, plotH = H - padT - padB;

    cctx.strokeStyle = "#38BDF8";
    cctx.lineWidth = 2;
    cctx.beginPath();
    history.forEach((h, i) => {
      const x = padL + (h.round / maxRound) * plotW;
      const y = padT + (1 - h.overall) * plotH;
      if (i === 0) cctx.moveTo(x, y); else cctx.lineTo(x, y);
    });
    cctx.stroke();
  }

  function updateReadouts() {
    const overall = window.AdoptionSim.fractionOf(agents, null);
    readouts.overall1.textContent = pct(overall);
    readouts.overall2.textContent = pct(overall);
    readouts.airline.textContent = pct(window.AdoptionSim.fractionOf(agents, "airline"));
    readouts.largeFF.textContent = pct(window.AdoptionSim.fractionOf(agents, "largeFF"));
    readouts.smallFF.textContent = pct(window.AdoptionSim.fractionOf(agents, "smallFF"));
    readouts.customs.textContent = pct(window.AdoptionSim.fractionOf(agents, "customs"));
    readouts.intermediary.textContent = pct(window.AdoptionSim.fractionOf(agents, "intermediary"));
    roundLabel.textContent = String(round);
  }

  function reset() {
    clearInterval(timer); timer = null;
    playBtn.textContent = "▶ 运行模拟";
    agents = window.AdoptionSim.create(SEED);
    round = 0;
    history = [{ round: 0, overall: window.AdoptionSim.fractionOf(agents, null) }];
    drawNetwork(); drawChart(); updateReadouts();
  }

  function tick() {
    const overallBefore = window.AdoptionSim.fractionOf(agents, null);
    window.AdoptionSim.step(agents, round, scenarioSel.value, overallBefore);
    round += 1;
    history.push({ round, overall: window.AdoptionSim.fractionOf(agents, null) });
    drawNetwork(); drawChart(); updateReadouts();
    if (round >= window.AdoptionSim.N_ROUNDS) {
      clearInterval(timer); timer = null;
      playBtn.textContent = "▶ 运行模拟";
    }
  }

  playBtn.addEventListener("click", () => {
    if (timer) { clearInterval(timer); timer = null; playBtn.textContent = "▶ 运行模拟"; return; }
    if (round >= window.AdoptionSim.N_ROUNDS) reset();
    playBtn.textContent = "⏸ 暂停";
    timer = setInterval(tick, 260);
  });

  resetBtn.addEventListener("click", reset);
  scenarioSel.addEventListener("change", reset);

  reset();
})();
