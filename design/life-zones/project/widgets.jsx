// 3 iOS widgets — Small (2×2), Medium (4×2), Lock screen rectangular

function WidgetsBoard() {
  return (
    <div style={{ background: LZ.paper, padding: 56, width: 1180,
      fontFamily: LZ.font, color: LZ.ink, boxSizing: 'border-box' }}>
      <header style={{ marginBottom: 36, paddingBottom: 18, borderBottom: `1px solid ${LZ.rule}` }}>
        <div style={{ fontSize: 11, letterSpacing: '0.22em', textTransform: 'uppercase', color: LZ.inkMute, fontWeight: 600 }}>
          E — Widgets
        </div>
        <h2 style={{ margin: '8px 0 6px', fontSize: 32, fontWeight: 500, letterSpacing: '-0.018em' }}>
          Glanceable, never demanding.
        </h2>
        <p style={{ margin: 0, fontSize: 15, color: LZ.inkSoft, maxWidth: 560, lineHeight: 1.55 }}>
          Three widgets for the home screen and lock screen. Each shows just enough to ask:
          <em style={{ fontFamily: LZ.fontSerif }}> what shape am I, this week?</em>
        </p>
      </header>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1.6fr', gap: 40, alignItems: 'start' }}>
        {/* Left: home screen with small + medium */}
        <div>
          <div style={{ fontSize: 11, letterSpacing: '0.22em', textTransform: 'uppercase',
            color: LZ.inkMute, fontWeight: 600, marginBottom: 16 }}>Home screen</div>
          <HomeScreenContext>
            <WidgetSmall/>
            <span style={{ width: 158 }}/>
            <WidgetMedium/>
          </HomeScreenContext>
          <div style={{ marginTop: 22, display: 'flex', gap: 28 }}>
            <SpecBlock title="Small · 2 × 2">
              Radar polygon as the hero, average score below.
              Background tinted to the dominant zone — never above 8% saturation.
            </SpecBlock>
            <SpecBlock title="Medium · 4 × 2">
              Seven rows. Colored dot · zone · thin bar · score.
              No average, no streaks, no decoration.
            </SpecBlock>
          </div>
        </div>

        {/* Right: lock screen */}
        <div>
          <div style={{ fontSize: 11, letterSpacing: '0.22em', textTransform: 'uppercase',
            color: LZ.inkMute, fontWeight: 600, marginBottom: 16 }}>Lock screen</div>
          <LockScreenContext>
            <WidgetLock/>
          </LockScreenContext>
          <SpecBlock title="Lock screen · rectangular accessory" style={{ marginTop: 22 }}>
            Three zones that need care this week. White-on-glass via Apple's
            <em style={{ fontFamily: LZ.fontSerif }}> .accessoryRectangular</em> family.
            Color dots, names, scores. Nothing else.
          </SpecBlock>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Small widget — 2 × 2 (~158pt square)
// ─────────────────────────────────────────────────────────────
function WidgetSmall({ size = 158 }) {
  const avg = (Object.values(SCORES).reduce((a,b)=>a+b,0)/7).toFixed(1);
  return (
    <div style={{
      width: size, height: size, borderRadius: 22, overflow: 'hidden',
      position: 'relative',
      // Tinted to dominant zone (Deep Work, blue) at low saturation
      background: 'linear-gradient(160deg, #F2EBDC 0%, #E6E4DC 100%)',
      boxShadow: '0 6px 16px rgba(40,30,15,0.10), 0 0 0 0.5px rgba(40,30,15,0.05)',
      padding: 10,
      display: 'flex', flexDirection: 'column', justifyContent: 'space-between',
    }}>
      {/* small wordmark */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div style={{ fontSize: 9, letterSpacing: '0.18em', textTransform: 'uppercase',
          color: LZ.inkMute, fontWeight: 600 }}>Life Zones</div>
        <IconMark size={14} color={LZ.tealDeep} bg="transparent" rounded={3}/>
      </div>
      {/* Mini radar */}
      <div style={{ position: 'absolute', top: '50%', left: '50%',
        transform: 'translate(-50%, -54%)' }}>
        <RadarMap size={108} showLabels={false} showRings={false}
          dotRadius={3} stroke={LZ.tealDeep} fill={LZ.teal} fillOpacity={0.20}/>
      </div>
      {/* Avg */}
      <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between' }}>
        <span style={{ fontSize: 26, fontWeight: 500, color: LZ.ink,
          fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.025em', lineHeight: 1 }}>{avg}</span>
        <span style={{ fontSize: 9, letterSpacing: '0.2em', textTransform: 'uppercase',
          color: LZ.inkMute, fontWeight: 600 }}>avg</span>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Medium widget — 4 × 2 (~338 × 158)
// ─────────────────────────────────────────────────────────────
function WidgetMedium() {
  return (
    <div style={{
      width: 338, height: 158, borderRadius: 22, overflow: 'hidden',
      background: LZ.paper,
      boxShadow: '0 6px 16px rgba(40,30,15,0.10), 0 0 0 0.5px rgba(40,30,15,0.05)',
      padding: '12px 14px 12px',
      display: 'flex', flexDirection: 'column',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 6 }}>
        <div style={{ fontSize: 11.5, fontWeight: 500, color: LZ.ink, letterSpacing: '-0.005em' }}>Life Zones</div>
        <div style={{ fontSize: 9, letterSpacing: '0.18em', textTransform: 'uppercase',
          color: LZ.inkMute, fontWeight: 600 }}>May 25</div>
      </div>
      <div style={{ flex: 1, display: 'grid', gridTemplateRows: 'repeat(7, 1fr)', rowGap: 1 }}>
        {ZONES.map((z) => {
          const v = SCORES[z.key];
          const pct = (v / 10) * 100;
          return (
            <div key={z.key} style={{ display: 'grid',
              gridTemplateColumns: '7px 60px 1fr 22px', alignItems: 'center', gap: 8 }}>
              <span style={{ width: 5, height: 5, borderRadius: 3, background: z.color, justifySelf: 'center' }}/>
              <span style={{ fontSize: 9.5, color: LZ.ink, fontWeight: 500 }}>{z.name}</span>
              <div style={{ height: 3, background: '#E8DFC8', borderRadius: 2,
                position: 'relative', overflow: 'hidden' }}>
                <div style={{ position: 'absolute', inset: 0, width: `${pct}%`,
                  background: z.color, borderRadius: 2 }}/>
              </div>
              <span style={{ fontSize: 10, color: LZ.ink, fontWeight: 500,
                fontVariantNumeric: 'tabular-nums', textAlign: 'right' }}>{v.toFixed(1)}</span>
            </div>
          );
        })}
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Lock screen widget — rectangular accessory (~330 × 76)
// ─────────────────────────────────────────────────────────────
function WidgetLock() {
  const needsCare = [
    { ...ZONES[3], score: 5.8 }, // Inner World
    { ...ZONES[6], score: 6.2 }, // Growth
    { ...ZONES[0], score: 6.5 }, // Vitality
  ];
  return (
    <div style={{
      width: 330, padding: '10px 14px',
      borderRadius: 12, color: '#FFFFFF',
      // Lock screen widgets render against the wallpaper via vibrancy.
      // We approximate with a semi-transparent ink and inner ring.
      background: 'rgba(255,255,255,0.18)',
      backdropFilter: 'blur(10px)',
      WebkitBackdropFilter: 'blur(10px)',
      border: '0.5px solid rgba(255,255,255,0.3)',
    }}>
      <div style={{ fontSize: 9.5, letterSpacing: '0.18em', textTransform: 'uppercase',
        fontWeight: 700, opacity: 0.85, marginBottom: 4 }}>Needs care</div>
      <div style={{ display: 'flex', justifyContent: 'space-between' }}>
        {needsCare.map((z) => (
          <div key={z.key} style={{ display: 'flex', alignItems: 'baseline', gap: 6 }}>
            <span style={{ width: 6, height: 6, borderRadius: 3, background: z.color }}/>
            <span style={{ fontSize: 12, fontWeight: 600 }}>{z.name}</span>
            <span style={{ fontSize: 12, fontWeight: 500, opacity: 0.85,
              fontVariantNumeric: 'tabular-nums' }}>{z.score.toFixed(1)}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Home screen mockup background — strip of dock + a few app icons
// ─────────────────────────────────────────────────────────────
function HomeScreenContext({ children }) {
  return (
    <div style={{
      position: 'relative', borderRadius: 36, overflow: 'hidden',
      padding: 22, paddingTop: 50, background: '#E8E2CE',
      boxShadow: '0 14px 30px rgba(40,30,15,0.12), inset 0 0 0 1px rgba(40,30,15,0.06)',
    }}>
      <div style={{ position: 'absolute', inset: 0, opacity: 0.5 }}>
        <TopoTexture width={600} height={500} lines={26}
          palette={['#A9B59A', '#8DA383']} seed={4} opacity={0.75} strokeWidth={0.8}/>
      </div>
      <div style={{ position: 'relative', display: 'flex', alignItems: 'center',
        gap: 12, flexWrap: 'wrap' }}>
        {children}
      </div>
    </div>
  );
}

function LockScreenContext({ children }) {
  return (
    <div style={{
      position: 'relative', borderRadius: 36, overflow: 'hidden',
      padding: '40px 30px 30px', background: '#2C3741',
      boxShadow: '0 14px 30px rgba(40,30,15,0.18)',
    }}>
      <div style={{ position: 'absolute', inset: 0, opacity: 0.6 }}>
        <TopoTexture width={500} height={400} lines={26}
          palette={['#7D8FA3', '#536376']} seed={13} opacity={0.5} strokeWidth={0.9}/>
      </div>
      <div style={{ position: 'relative', color: '#fff', textAlign: 'center', marginBottom: 18 }}>
        <div style={{ fontSize: 12, opacity: 0.7 }}>Wednesday, May 27</div>
        <div style={{ fontSize: 78, fontWeight: 200, letterSpacing: '-0.04em', lineHeight: 0.95, marginTop: 4 }}>9:41</div>
      </div>
      <div style={{ position: 'relative', display: 'flex', justifyContent: 'center' }}>
        {children}
      </div>
    </div>
  );
}

function SpecBlock({ title, children, style }) {
  return (
    <div style={{ flex: 1, ...style }}>
      <div style={{ fontSize: 11, letterSpacing: '0.18em', textTransform: 'uppercase',
        color: LZ.inkMute, fontWeight: 600, marginBottom: 6 }}>{title}</div>
      <div style={{ fontSize: 13, color: LZ.inkSoft, lineHeight: 1.55 }}>{children}</div>
    </div>
  );
}

Object.assign(window, { WidgetsBoard, WidgetSmall, WidgetMedium, WidgetLock });
