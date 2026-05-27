// Map screen — the radar map of the week's 7 zones

function MapScreen() {
  const week = 'Week of May 25';
  const avg = (Object.values(SCORES).reduce((a, b) => a + b, 0) / 7).toFixed(1);
  return (
    <Phone label="Map">
      {/* Top bar */}
      <div style={{ padding: '4px 24px 8px', display: 'flex',
        alignItems: 'baseline', justifyContent: 'space-between' }}>
        <div style={{ fontSize: 19, fontWeight: 500, letterSpacing: '-0.018em', color: LZ.ink }}>
          Life Zones
        </div>
        <div style={{ fontSize: 11.5, letterSpacing: '0.06em', textTransform: 'uppercase',
          color: LZ.inkMute, fontWeight: 500 }}>{week}</div>
      </div>

      {/* Canvas card with radar */}
      <div style={{ padding: '8px 18px 0' }}>
        <div style={{ position: 'relative', background: LZ.cream,
          borderRadius: 18, padding: '14px 8px 10px',
          border: `1px solid ${LZ.ruleSoft}` }}>
          {/* Map decorations: corner ticks */}
          <CornerTicks/>
          {/* Whisper-faint topo behind the radar */}
          <div style={{ position: 'absolute', inset: 0, opacity: 0.20,
            mixBlendMode: 'multiply', pointerEvents: 'none', overflow: 'hidden',
            borderRadius: 18 }}>
            <TopoTexture width={400} height={400} lines={14}
              palette={['#B6A88B']} seed={3} opacity={0.55} strokeWidth={0.8}/>
          </div>
          <div style={{ display: 'flex', justifyContent: 'center', position: 'relative' }}>
            <RadarMap size={342} stroke={LZ.tealDeep} fill={LZ.teal} fillOpacity={0.16}
              ringColor="#C2B79C" dotRadius={5.5}/>
          </div>
          {/* Center badge — average */}
          <div style={{
            position: 'absolute', top: '50%', left: '50%',
            transform: 'translate(-50%, calc(-50% - 4px))',
            textAlign: 'center', pointerEvents: 'none',
          }}>
            <div style={{ fontSize: 9, letterSpacing: '0.22em', textTransform: 'uppercase',
              color: LZ.inkMute, fontWeight: 600 }}>avg</div>
            <div style={{ fontSize: 26, fontWeight: 500, color: LZ.ink,
              fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.02em' }}>{avg}</div>
          </div>
          {/* Legend pin: top-left */}
          <div style={{ position: 'absolute', top: 12, left: 14,
            display: 'flex', alignItems: 'center', gap: 6,
            fontSize: 9.5, letterSpacing: '0.16em', textTransform: 'uppercase',
            color: LZ.inkMute, fontWeight: 600 }}>
            <span style={{ width: 6, height: 6, borderRadius: 4, background: LZ.tealDeep, opacity: 0.7 }}/>
            this week
          </div>
          {/* Legend pin: top-right */}
          <div style={{ position: 'absolute', top: 12, right: 14,
            fontSize: 9.5, letterSpacing: '0.16em', textTransform: 'uppercase',
            color: LZ.inkMute, fontWeight: 600 }}>
            scale 0 — 10
          </div>
        </div>
      </div>

      {/* Zones list */}
      <div style={{ flex: 1, overflow: 'auto', padding: '20px 24px 110px', position: 'relative' }}>
        <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 10 }}>
          <div style={{ fontSize: 11, letterSpacing: '0.22em', textTransform: 'uppercase', color: LZ.inkMute, fontWeight: 600 }}>
            By zone
          </div>
          <div style={{ fontSize: 11, color: LZ.inkMute }}>
            <span style={{ borderBottom: `0.5px solid ${LZ.inkMute}` }}>Compare ▾</span>
          </div>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column' }}>
          {ZONES.map((z, i) => (
            <ZoneRow key={z.key} zone={z} score={SCORES[z.key]} isLast={i === ZONES.length - 1}/>
          ))}
        </div>
      </div>

      <TabBar active="map"/>
    </Phone>
  );
}

function ZoneRow({ zone, score, isLast }) {
  const pct = (score / 10) * 100;
  return (
    <div style={{
      display: 'grid', gridTemplateColumns: '14px 1fr auto',
      alignItems: 'center', gap: 12, padding: '14px 0',
      borderBottom: isLast ? 'none' : `0.5px solid ${LZ.ruleSoft}`,
    }}>
      <span style={{ width: 8, height: 8, borderRadius: 4, background: zone.color,
        boxShadow: `0 0 0 3px ${zone.color}22` }}/>
      <div style={{ minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <span style={{ fontSize: 15, fontWeight: 500, color: LZ.ink, letterSpacing: '-0.005em' }}>
            {zone.name}
          </span>
          <span style={{ fontSize: 10.5, color: LZ.inkMute, fontWeight: 500,
            letterSpacing: '0.04em' }}>{zone.blurb}</span>
        </div>
        <div style={{ marginTop: 7, height: 4, background: '#E2D8C0', borderRadius: 2,
          position: 'relative', overflow: 'hidden' }}>
          <div style={{ position: 'absolute', inset: 0, width: `${pct}%`,
            background: zone.color, borderRadius: 2 }}/>
        </div>
      </div>
      <div style={{ fontSize: 18, fontWeight: 500, color: LZ.ink,
        fontVariantNumeric: 'tabular-nums', minWidth: 34, textAlign: 'right',
        letterSpacing: '-0.01em' }}>{score.toFixed(1)}</div>
    </div>
  );
}

function CornerTicks() {
  const tick = (style) => (
    <div style={{
      position: 'absolute', width: 14, height: 14, ...style,
      borderColor: LZ.inkMute, opacity: 0.45,
    }}/>
  );
  return (
    <>
      {tick({ top: 6, left: 6, borderTop: '0.5px solid', borderLeft: '0.5px solid' })}
      {tick({ top: 6, right: 6, borderTop: '0.5px solid', borderRight: '0.5px solid' })}
      {tick({ bottom: 6, left: 6, borderBottom: '0.5px solid', borderLeft: '0.5px solid' })}
      {tick({ bottom: 6, right: 6, borderBottom: '0.5px solid', borderRight: '0.5px solid' })}
    </>
  );
}

Object.assign(window, { MapScreen });
