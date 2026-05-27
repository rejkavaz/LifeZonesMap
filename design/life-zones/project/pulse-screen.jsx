// Pulse Report screen — monthly view
// "Data journalism meets mindfulness. NYT Upshot × Calm."

function PulseScreen() {
  // 4 weeks of data for May
  const weeks = ['W1', 'W2', 'W3', 'W4'];
  const series = {
    vit:  [5.5, 6.0, 6.2, 6.5],
    work: [7.2, 7.5, 7.8, 8.2],
    con:  [6.0, 6.5, 7.2, 7.0],
    inn:  [6.5, 6.0, 5.5, 5.8],
    cre:  [6.0, 6.8, 7.0, 7.5],
    fnd:  [6.5, 7.0, 7.6, 8.0],
    gro:  [5.0, 5.5, 6.0, 6.2],
  };
  const avg = (Object.values(SCORES).reduce((a,b)=>a+b,0)/7).toFixed(1);

  return (
    <Phone label="Pulse Report">
      {/* Header */}
      <div style={{ padding: '6px 24px 8px' }}>
        <div style={{ fontSize: 11, letterSpacing: '0.22em', textTransform: 'uppercase',
          color: LZ.inkMute, fontWeight: 600 }}>Pulse Report</div>
        <div style={{ marginTop: 4, display: 'flex', alignItems: 'baseline', justifyContent: 'space-between' }}>
          <div style={{ fontSize: 30, fontWeight: 500, color: LZ.ink, letterSpacing: '-0.022em' }}>May</div>
          <div style={{ fontSize: 12, color: LZ.inkMute }}>4 check-ins · 2026</div>
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'auto', padding: '6px 18px 110px' }}>
        {/* Stat cards */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8 }}>
          <StatCard label="Avg score"
            value={avg} sub="of 10"/>
          <StatCard label="Most improved"
            value="Deep Work" sub="+1.0" trendUp color={LZ.zDeepWork}/>
          <StatCard label="Most consistent"
            value="Foundation" sub="σ 0.4" color={LZ.zFound}/>
        </div>

        {/* Line chart */}
        <SectionTitle>Across the month</SectionTitle>
        <div style={{ background: LZ.paper, border: `0.5px solid ${LZ.ruleSoft}`,
          borderRadius: 14, padding: '14px 14px 12px' }}>
          <LineChart weeks={weeks} series={series}/>
          {/* Custom legend */}
          <div style={{ marginTop: 10, display: 'grid',
            gridTemplateColumns: '1fr 1fr', gap: '4px 12px' }}>
            {ZONES.map((z) => (
              <div key={z.key} style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
                <span style={{ width: 14, height: 2, borderRadius: 1, background: z.color }}/>
                <span style={{ fontSize: 11, color: LZ.inkSoft, fontWeight: 500 }}>{z.name}</span>
                <span style={{ marginLeft: 'auto', fontSize: 10.5, color: LZ.inkMute,
                  fontVariantNumeric: 'tabular-nums' }}>
                  {series[z.key][0].toFixed(1)} → {series[z.key][3].toFixed(1)}
                </span>
              </div>
            ))}
          </div>
        </div>

        {/* Insight cards */}
        <SectionTitle>What we noticed</SectionTitle>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          <Insight kind="positive" zone="Deep Work"
            body="Four weeks of steady climb. Whatever you changed in week two — keep it.">
            <ZoneGlyph glyph="focus" size={16}/>
          </Insight>
          <Insight kind="correlation"
            body="On weeks when Vitality is high, Inner World tends to follow within seven days. Sleep, then steadiness.">
            <ZoneGlyph glyph="moon" size={16}/>
          </Insight>
          <Insight kind="warning" zone="Inner World"
            body="Drifting downward since W1. Nothing alarming — but worth ten quiet minutes this week.">
            <ZoneGlyph glyph="moon" size={16}/>
          </Insight>
        </div>

        {/* Zone connections */}
        <SectionTitle>How your zones move together</SectionTitle>
        <div style={{ background: LZ.paper, border: `0.5px solid ${LZ.ruleSoft}`,
          borderRadius: 14, padding: '14px 12px 14px' }}>
          <div style={{ display: 'flex', justifyContent: 'center' }}>
            <ConnectionDiagram size={300}/>
          </div>
          <div style={{ marginTop: 4, padding: '0 6px', fontSize: 11.5,
            color: LZ.inkSoft, lineHeight: 1.55, fontFamily: LZ.fontSerif, fontStyle: 'italic' }}>
            Thicker lines mean a stronger pull between two zones over the last twelve weeks.
          </div>
        </div>
      </div>

      <TabBar active="pulse"/>
    </Phone>
  );
}

// ─────────────────────────────────────────────────────────────
function SectionTitle({ children }) {
  return (
    <div style={{ marginTop: 22, marginBottom: 10, display: 'flex', alignItems: 'center', gap: 10 }}>
      <span style={{ fontSize: 11, letterSpacing: '0.22em', textTransform: 'uppercase',
        color: LZ.inkMute, fontWeight: 600 }}>{children}</span>
      <span style={{ flex: 1, height: 0.5, background: LZ.ruleSoft }}/>
    </div>
  );
}

function StatCard({ label, value, sub, trendUp, color }) {
  return (
    <div style={{
      background: LZ.paper, border: `0.5px solid ${LZ.ruleSoft}`,
      borderRadius: 12, padding: '12px 10px 12px',
      minHeight: 84, display: 'flex', flexDirection: 'column',
    }}>
      <div style={{ fontSize: 9.5, letterSpacing: '0.2em', textTransform: 'uppercase',
        color: LZ.inkMute, fontWeight: 600 }}>{label}</div>
      <div style={{ marginTop: 8, fontSize: value.length > 6 ? 14 : 20,
        fontWeight: 500, color: color || LZ.ink, letterSpacing: '-0.012em', lineHeight: 1.1 }}>
        {value}
      </div>
      <div style={{ marginTop: 'auto', display: 'flex', alignItems: 'center', gap: 4,
        fontSize: 10.5, color: LZ.inkSoft, fontVariantNumeric: 'tabular-nums' }}>
        {trendUp && (
          <svg width="9" height="9" viewBox="0 0 12 12" fill="none">
            <path d="M2 9L6 3l4 6" stroke={color || LZ.tealDeep} strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        )}
        {sub}
      </div>
    </div>
  );
}

function Insight({ kind, zone, body, children }) {
  const palette = {
    warning:     { accent: '#C19036', bg: '#F8EFD8', label: 'Watch'   },
    positive:    { accent: '#5E8C5A', bg: '#E7EDDE', label: 'Lift'    },
    correlation: { accent: '#3C6E91', bg: '#DEE7EF', label: 'Pattern' },
  }[kind];
  return (
    <div style={{
      background: '#FFFFFF',
      border: `0.5px solid ${LZ.ruleSoft}`,
      borderRadius: 12, padding: '11px 13px 12px 14px', position: 'relative',
      paddingLeft: 18, overflow: 'hidden',
    }}>
      <div style={{ position: 'absolute', top: 0, bottom: 0, left: 0, width: 4, background: palette.accent }}/>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 }}>
        <span style={{
          fontSize: 9, letterSpacing: '0.22em', textTransform: 'uppercase',
          color: palette.accent, fontWeight: 700,
        }}>{palette.label}{zone ? ` · ${zone}` : ''}</span>
        <span style={{ flex: 1 }}/>
        <span style={{ color: palette.accent, opacity: 0.7 }}>{children}</span>
      </div>
      <div style={{ fontSize: 13.5, color: LZ.ink, lineHeight: 1.45,
        letterSpacing: '-0.005em', maxWidth: 320 }}>{body}</div>
    </div>
  );
}

// Line chart — 7 series on a single 0–10 chart
function LineChart({ weeks, series }) {
  const W = 318, H = 170;
  const pad = { l: 22, r: 8, t: 8, b: 22 };
  const xs = (i) => pad.l + (i / (weeks.length - 1)) * (W - pad.l - pad.r);
  const ys = (v) => pad.t + (1 - v / 10) * (H - pad.t - pad.b);

  return (
    <svg width="100%" viewBox={`0 0 ${W} ${H}`} style={{ display: 'block', overflow: 'visible' }}>
      {/* y gridlines */}
      {[0, 2.5, 5, 7.5, 10].map((v) => (
        <g key={v}>
          <line x1={pad.l} y1={ys(v)} x2={W - pad.r} y2={ys(v)}
            stroke={LZ.rule} strokeWidth="0.5"
            strokeDasharray={v === 0 || v === 10 ? '0' : '3 3'}/>
          <text x={pad.l - 4} y={ys(v) + 3} textAnchor="end"
            fontSize="9" fill={LZ.inkMute} fontFamily={LZ.font}
            fontVariantNumeric="tabular-nums">{v}</text>
        </g>
      ))}
      {/* x labels */}
      {weeks.map((w, i) => (
        <text key={w} x={xs(i)} y={H - 6} textAnchor="middle"
          fontSize="9.5" fill={LZ.inkMute} fontFamily={LZ.font} fontWeight="600">{w}</text>
      ))}
      {/* lines */}
      {ZONES.map((z) => {
        const data = series[z.key];
        const d = data.map((v, i) => `${i ? 'L' : 'M'}${xs(i).toFixed(1)},${ys(v).toFixed(1)}`).join(' ');
        return (
          <g key={z.key}>
            <path d={d} fill="none" stroke={z.color} strokeWidth="1.6"
              strokeLinecap="round" strokeLinejoin="round" opacity="0.92"/>
            {data.map((v, i) => (
              <circle key={i} cx={xs(i)} cy={ys(v)} r={i === data.length - 1 ? 2.6 : 1.6}
                fill={z.color}/>
            ))}
            {/* end label */}
            <text x={xs(data.length - 1) + 4} y={ys(data[data.length - 1]) + 2.5}
              fontSize="8.5" fill={z.color} fontFamily={LZ.font} fontWeight="600"
              fontVariantNumeric="tabular-nums">
              {data[data.length - 1].toFixed(1)}
            </text>
          </g>
        );
      })}
    </svg>
  );
}

// Zone connections — circular graph
function ConnectionDiagram({ size = 300 }) {
  const cx = size / 2, cy = size / 2;
  const R = size * 0.36;
  const N = ZONES.length;
  const pos = ZONES.map((_, i) => {
    const a = -Math.PI / 2 + (i / N) * Math.PI * 2;
    return [cx + Math.cos(a) * R, cy + Math.sin(a) * R, a];
  });
  // Weighted edges (0..1)
  const edges = [
    ['vit',  'inn', 0.85],
    ['vit',  'gro', 0.55],
    ['work', 'cre', 0.78],
    ['work', 'fnd', 0.62],
    ['con',  'inn', 0.72],
    ['con',  'gro', 0.5],
    ['cre',  'gro', 0.66],
    ['inn',  'fnd', 0.42],
    ['vit',  'work', 0.4],
    ['fnd',  'gro', 0.35],
  ];
  const idx = Object.fromEntries(ZONES.map((z, i) => [z.key, i]));
  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} style={{ display: 'block' }}>
      {/* faint ring */}
      <circle cx={cx} cy={cy} r={R} fill="none" stroke={LZ.rule} strokeDasharray="2 4"/>
      {edges.map(([a, b, w], i) => {
        const [x1, y1] = pos[idx[a]];
        const [x2, y2] = pos[idx[b]];
        return (
          <line key={i} x1={x1} y1={y1} x2={x2} y2={y2}
            stroke={LZ.inkSoft} strokeOpacity={0.18 + w * 0.5}
            strokeWidth={0.6 + w * 2.2} strokeLinecap="round"/>
        );
      })}
      {ZONES.map((z, i) => {
        const [x, y, a] = pos[i];
        const isRight = Math.cos(a) > 0.2, isLeft = Math.cos(a) < -0.2;
        const anchor = isRight ? 'start' : isLeft ? 'end' : 'middle';
        const dx = isRight ? 10 : isLeft ? -10 : 0;
        const dy = Math.sin(a) > 0.2 ? 16 : Math.sin(a) < -0.2 ? -8 : 4;
        return (
          <g key={z.key}>
            <circle cx={x} cy={y} r="9" fill={LZ.paper} stroke={z.color} strokeWidth="1.4"/>
            <circle cx={x} cy={y} r="4" fill={z.color}/>
            <text x={x + dx} y={y + dy} textAnchor={anchor}
              fontSize="10" fill={LZ.ink} fontWeight="500" fontFamily={LZ.font}>
              {z.name}
            </text>
          </g>
        );
      })}
    </svg>
  );
}

Object.assign(window, { PulseScreen });
