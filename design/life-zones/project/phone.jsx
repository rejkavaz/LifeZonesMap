// Custom iPhone 15 Pro frame — minimal, designed for the Life Zones aesthetic.
// 393×852 logical size, dynamic island, home indicator. Cream background.

function Phone({ children, width = 393, height = 852, bg, statusDark = false, label }) {
  return (
    <div style={{ display: 'inline-block', position: 'relative' }}>
      <div style={{
        width, height, borderRadius: 54, overflow: 'hidden',
        position: 'relative', background: bg || LZ.paper,
        boxShadow: '0 28px 60px rgba(40,30,15,0.18), 0 0 0 1px rgba(40,30,15,0.18), inset 0 0 0 6px #111, inset 0 0 0 7px #2A2823',
        fontFamily: LZ.font,
        WebkitFontSmoothing: 'antialiased',
      }}>
        {/* dynamic island */}
        <div style={{
          position: 'absolute', top: 11, left: '50%', transform: 'translateX(-50%)',
          width: 122, height: 36, borderRadius: 22, background: '#0A0A0A', zIndex: 50,
        }}/>
        {/* status bar */}
        <StatusBar dark={statusDark}/>
        {/* content */}
        <div style={{ position: 'absolute', inset: 0, paddingTop: 54, paddingBottom: 0,
          display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
          {children}
        </div>
        {/* home indicator */}
        <div style={{
          position: 'absolute', bottom: 8, left: '50%', transform: 'translateX(-50%)',
          width: 134, height: 5, borderRadius: 100,
          background: statusDark ? 'rgba(255,255,255,0.55)' : 'rgba(40,35,32,0.42)',
          zIndex: 60,
        }}/>
      </div>
      {label && (
        <div style={{ marginTop: 14, fontSize: 11, letterSpacing: '0.18em',
          textTransform: 'uppercase', color: LZ.inkMute, textAlign: 'center' }}>{label}</div>
      )}
    </div>
  );
}

function StatusBar({ dark = false }) {
  const c = dark ? '#fff' : LZ.ink;
  return (
    <div style={{
      position: 'absolute', top: 0, left: 0, right: 0, zIndex: 20,
      display: 'flex', justifyContent: 'space-between', alignItems: 'center',
      padding: '17px 32px 0', height: 54, boxSizing: 'border-box',
    }}>
      <span style={{ fontSize: 15.5, fontWeight: 600, color: c, fontFamily: '-apple-system, "SF Pro", system-ui' }}>9:41</span>
      <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
        <svg width="17" height="11" viewBox="0 0 17 11">
          <rect x="0" y="6.5" width="2.8" height="4" rx="0.5" fill={c}/>
          <rect x="4.2" y="4.5" width="2.8" height="6" rx="0.5" fill={c}/>
          <rect x="8.4" y="2.5" width="2.8" height="8" rx="0.5" fill={c}/>
          <rect x="12.6" y="0" width="2.8" height="10.5" rx="0.5" fill={c}/>
        </svg>
        <svg width="15" height="11" viewBox="0 0 15 11">
          <path d="M7.5 2.8c2 0 3.8.8 5 2L13.6 3.8C12 2.2 9.9 1.2 7.5 1.2S3 2.2 1.4 3.8L2.5 4.8c1.2-1.2 3-2 5-2z" fill={c}/>
          <path d="M7.5 5.9c1.2 0 2.3.5 3.1 1.3L11.7 6.1c-1.1-1.1-2.6-1.8-4.2-1.8S4.4 5 3.3 6.1l1.1 1.1c.8-.8 1.9-1.3 3.1-1.3z" fill={c}/>
          <circle cx="7.5" cy="9.3" r="1.3" fill={c}/>
        </svg>
        <svg width="25" height="12" viewBox="0 0 25 12">
          <rect x="0.5" y="0.5" width="21" height="11" rx="3" stroke={c} strokeOpacity="0.4" fill="none"/>
          <rect x="2" y="2" width="18" height="8" rx="1.6" fill={c}/>
          <path d="M23 4v4c.6-.2 1-.9 1-2s-.4-1.8-1-2z" fill={c} fillOpacity="0.45"/>
        </svg>
      </div>
    </div>
  );
}

// Bottom tab bar — Map / Check In / Pulse
function TabBar({ active = 'map' }) {
  const tabs = [
    { id: 'map',    label: 'Map',      icon: 'map' },
    { id: 'check',  label: 'Check In', icon: 'check' },
    { id: 'pulse',  label: 'Pulse',    icon: 'pulse' },
  ];
  return (
    <div style={{
      position: 'absolute', bottom: 0, left: 0, right: 0, zIndex: 30,
      paddingBottom: 28, paddingTop: 14, paddingLeft: 24, paddingRight: 24,
      background: 'linear-gradient(to bottom, rgba(242,235,220,0) 0%, rgba(242,235,220,0.94) 28%, ' + LZ.paper + ' 60%)',
      display: 'flex', justifyContent: 'space-around', alignItems: 'center',
      borderTop: `0.5px solid ${LZ.ruleSoft}`,
    }}>
      {tabs.map((t) => {
        const isActive = t.id === active;
        return (
          <div key={t.id} style={{
            display: 'flex', flexDirection: 'column', alignItems: 'center',
            gap: 4, color: isActive ? LZ.tealDeep : LZ.inkMute,
          }}>
            <TabIcon icon={t.icon} active={isActive}/>
            <div style={{ fontSize: 10.5, fontWeight: isActive ? 600 : 500, letterSpacing: '0.04em' }}>{t.label}</div>
          </div>
        );
      })}
    </div>
  );
}

function TabIcon({ icon, active }) {
  const s = { width: 22, height: 22, fill: 'none', stroke: 'currentColor',
    strokeWidth: active ? 1.8 : 1.5, strokeLinecap: 'round', strokeLinejoin: 'round' };
  if (icon === 'map') return (
    <svg viewBox="0 0 24 24" {...s}>
      <polygon points="12,3 21,8 12,13 3,8" />
      <polygon points="12,13 21,18 12,21 3,18" strokeDasharray={active ? '0' : '2 2'}/>
    </svg>
  );
  if (icon === 'check') return (
    <svg viewBox="0 0 24 24" {...s}>
      <rect x="4" y="4" width="16" height="16" rx="3"/>
      <path d="M8 12l3 3 5-6"/>
    </svg>
  );
  if (icon === 'pulse') return (
    <svg viewBox="0 0 24 24" {...s}>
      <path d="M3 12h4l2-5 3 10 2-6 2 3h5"/>
    </svg>
  );
  return null;
}

Object.assign(window, { Phone, StatusBar, TabBar, TabIcon });
