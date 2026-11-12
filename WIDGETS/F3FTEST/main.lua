-- Pocket_f3f 1.2 Voice TEST - countdown and race-end voices; stable flight unchanged
-- No RF functions, no model configuration changes.
local sin,cos,sqrt,abs,pi=math.sin,math.cos,math.sqrt,math.abs,math.pi
local function C(r,g,b) return lcd.RGB(r,g,b) end
local SKY=C(161,207,235);local SEA=C(50,134,168)
local LAND=C(99,111,81);local CLIFF=C(189,151,108);local SAND=C(222,194,142)
local TOP=C(255,211,36);local BOTTOM=C(45,54,69);local TIP=C(249,86,27)
local WHITE=C(241,242,239);local INK=C(22,49,72)
local function lim(v,a,b) if v<a then return a elseif v>b then return b else return v end end
local function stick(name)
 local v=getValue(name)
 if type(v)~='number' then return 0 end
 return lim(v/1024,-1,1)
end
local function create(zone,options)
 return {zone=zone,last=getTime(),timer=getTime(),frames=0,fps=0,
 x=0,y=-18,z=33,heading=pi/2,bank=0,pitch=0,velocity=34, lift=0,crashed=false,resetHeld=false,
 launch=0, prepStart=getTime(),runStart=nil,runEnd=nil,entered=false,legs=0,nextBase=nil,baseLast=0,finishTone=false,lastCount=31,penalties=0,penLast=0,rearActive=false,lastSignal=0,lastWhistle=-600,pendingBaseTone=0,pendingBaseAt=0,voiceLaunch=false,voiceThirty=false,pendingRaceVoice=nil,pendingRaceVoiceAt=0}
end
local function triangle(a,b,c,col)
 lcd.drawFilledTriangle(math.floor(a[1]),math.floor(a[2]),math.floor(b[1]),math.floor(b[2]),math.floor(c[1]),math.floor(c[2]),col)
end
local function refresh(s,event,touch)
 local t=getTime(); local dt=lim((t-s.last)/100,0,0.14);s.last=t
 local rawA=stick('ail');local rawE=stick('ele')
 -- Invert directions requested from radio test; leave real radio model unchanged.
 local ail=-rawA;local ele=-rawE
 -- SH momentary switch: reset on positive transition, if present.
 local sh=getValue('sh')
 local held=type(sh)=='number' and sh>500
 if held and not s.resetHeld then
  s.x=0;s.y=-18;s.z=33;s.heading=pi/2;s.bank=0;s.pitch=0
  s.velocity=34;s.lift=0;s.crashed=false;s.last=t;dt=0
  s.prepStart=t;s.runStart=nil;s.runEnd=nil;s.entered=false;s.legs=0;s.nextBase=nil;s.baseLast=t;s.lastCount=31;s.penalties=0;s.penLast=0;s.rearActive=false;s.lastSignal=t;s.lastWhistle=t-600;s.pendingBaseTone=0;s.pendingBaseAt=0;s.voiceLaunch=false;s.voiceThirty=false;s.pendingRaceVoice=nil;s.pendingRaceVoiceAt=0
 end
 s.resetHeld=held
 -- Experimental voice announcements: separate WAVs in the existing Spanish sound directory.
 -- 30-second prompt is delayed so it does not overlap the launch announcement.
 -- Once the run has started, pending preparation announcements are suppressed.
 if not s.voiceLaunch and not s.crashed and type(playFile)=='function' then
  playFile('/SOUNDS/es/POCKETF3F/launch1.wav')
  s.voiceLaunch=true
 end
 if not s.voiceThirty and not s.entered and not s.runEnd and not s.crashed
     and t-s.prepStart>=145 and t-s.prepStart<900 and type(playFile)=='function' then
  playFile('/SOUNDS/es/POCKETF3F/thirty.wav')
  s.voiceThirty=true
 end
 -- Acoustic preparation: one event per countdown second transition.
 -- Low sound at 10/5, short high ticks at 4,3,2,1; distinct READY at zero.
 if not s.entered and not s.runEnd and not s.crashed then
  local remaining=math.max(0,30-math.floor((t-s.prepStart)/100))
  if remaining<s.lastCount then
   if type(playTone)=='function' then
    if remaining==10 then
      if type(playFile)=='function' then playFile('/SOUNDS/es/POCKETF3F/ten.wav')
      else playTone(740,130,0,0) end
    elseif remaining>=1 and remaining<=5 then
      local word=({[5]='five',[4]='four',[3]='three',[2]='two',[1]='one'})[remaining]
      if type(playFile)=='function' then playFile('/SOUNDS/es/POCKETF3F/'..word..'.wav')
      else playTone(1000,90,0,0) end
    elseif remaining==0 then playTone(1400,250,0,0) end
   end
   s.lastCount=remaining
  end
 end
 -- Stable controls/looping from v1.6 and v1.7 are unchanged.
 -- Crash freezes the aircraft until SH is pressed again.
 if not s.crashed then
  -- v3.0: v2.9 roll and center-stick feel, with stronger outer elevator.
  -- Control authority grows with airspeed, as aerodynamic pressure does.
  -- Keep v2.1 authority at 34 m/s; DO NOT reduce authority at low speed.
  -- Bounded factors avoid exaggerated response at the 75 m/s speed ceiling.
  local speedExcess=lim((s.velocity-34)/41,0,1)
  local rollGain=1+0.38*speedExcess
  local pitchGain=1+0.35*speedExcess
  local rollFeel=ail==0 and 0 or (ail>0 and 1 or -1)*abs(ail)^0.62
  s.bank=s.bank+rollFeel*dt*2.76*rollGain
  if s.bank>pi then s.bank=s.bank-2*pi elseif s.bank< -pi then s.bank=s.bank+2*pi end
  local cb=cos(s.bank);local sb=sin(s.bank)
  -- Softer center-to-mid-stick ramp for tight F3F turns without stick at stop.
  -- Preserve sign and zero; use progressive exponent below 1.
  local elevatorFeel=ele==0 and 0 or (ele>0 and 1 or -1)*abs(ele)^0.61
  -- v3.0: preserve center and mid-stick response of v2.9.
  -- Smoothly boost ONLY the last half of elevator stick travel.
  local outer=lim((abs(ele)-0.48)/0.52,0,1)
  local outerBoost=1+0.40*outer*outer*(3-2*outer)
  local elevatorRate=1.54*elevatorFeel*pitchGain*outerBoost
  s.pitch=s.pitch+elevatorRate*cb*dt
  if s.pitch>pi then s.pitch=s.pitch-2*pi elseif s.pitch< -pi then s.pitch=s.pitch+2*pi end
  -- More heading rotation at F3F speed: previous v2.5 turn radius was too wide.
  -- This modifies TURNING only; the looping pitch axis stays as before.
  local turnFactor=1.25+0.55*speedExcess
  s.heading=s.heading+(-elevatorRate*sb*.95*turnFactor - .18*sb)*dt
  -- Variable speed: accelerate descending, decelerate climbing.
  -- No arbitrary 5 m/s crawl: 12 m/s minimum pending future stall model.
  local shore=abs(s.y+12)
  local updraft=0
  if s.y<=20 and s.y>=-105 then
   updraft=2.8*lim(1-shore/100,0,1)*lim(1-(s.z-20)/180,0,1)
  end
  s.lift=updraft
  local v=s.velocity
  -- Small ridge-energy recovery offsets drag close to the slope.
  -- No artificial extra turning authority; preserves v2.1 control feel.
  local drag=.10+.00018*v*v
  local ridgeEnergy=updraft*.18
  v=lim(v+(-9.81*sin(s.pitch)-drag+ridgeEnergy)*dt,15,75)
  s.velocity=v
  local oldX=s.x;local oldY=s.y
  local nx=s.x+sin(s.heading)*v*dt
  local ny=s.y-cos(s.heading)*v*dt
  local nz=s.z+(sin(s.pitch)*v+updraft-.65)*dt
  -- Ground follows the rendered slope: plateau z=20, cliff z=0..20,
  -- beach/sea z=0. Collision uses current AND proposed position.
  local function terrainY(yy)
   if yy>=0 then return 20 end
   if yy>=-33 then return 20*(yy+33)/33 end
   return 0
  end
  local surface=math.max(terrainY(s.y),terrainY(ny))
  if nz<=surface+1.0 then
   s.x=nx;s.y=ny;s.z=surface+1.0;s.crashed=true
   if type(playTone)=='function' then playTone(280,400,0,PLAY_NOW or 0) end
  else
   s.x=nx;s.y=ny;s.z=nz
   -- F3F: A is x=-50, B is x=+50, separated by 100 m.
   -- Legal entry is crossing A INTO the course towards B (increasing x).
   -- Countdown begins on reset / launch (simplified simulator).
   -- At 30 seconds the official flight timer starts automatically,
   -- even if the model has NOT entered the course. Late time is included.
   if not s.runStart and t-s.prepStart>=3000 then
    s.runStart=s.prepStart+3000
    if type(playTone)=='function' then playTone(610,450,0,PLAY_NOW or 0) end
   end
   local crossAin=(oldX< -50 and nx>= -50)
   local crossAout=(oldX> -50 and nx<= -50)
   local crossBout=(oldX<50 and nx>=50)
   local crossBin=(oldX>50 and nx<=50)
   -- Safety plane is parallel to the course (rear, landward of ridge).
   -- Detect entry into rear airspace separately from base crossings.
   -- Register ONE penalty per excursion, not one per base or frame.
   -- Plane set 1.5 m landward of the ridge edge (y=0).
   local rearNow=(ny>1.5)
   if s.entered and not s.runEnd and rearNow and not s.rearActive then
    s.penalties=s.penalties+1;s.penLast=t
    s.lastSignal=t
    if type(playTone)=='function' then playTone(330,650,0,PLAY_NOW or 0) end
   end
   s.rearActive=rearNow
   -- Base crossings must still count and beep when behind the safety plane.
   -- Correct outward directions: B x>50, A x<-50.
   if not s.runEnd and t-s.baseLast>=35 then
    if not s.entered then
     -- Preparation phase: crossing A outwards (towards left) must beep,
     -- but it MUST NOT start the competition clock or count as a leg.
     if crossAout then
      s.baseLast=t
      s.lastSignal=t
      if type(playTone)=='function' then playTone(1040,115,0,PLAY_NOW or 0) end
     elseif crossAin then
      if not s.runStart then s.runStart=t end
      s.entered=true;s.nextBase=1;s.legs=0;s.baseLast=t
      s.lastSignal=t
      if type(playTone)=='function' then
       if t-s.penLast<85 and s.penLast>0 then s.pendingBaseTone=950;s.pendingBaseAt=t+85
       else playTone(950,170,0,PLAY_NOW or 0) end
      end
     end
    elseif (s.nextBase==1 and crossBout) or (s.nextBase==-1 and crossAout) then
     s.legs=s.legs+1
     s.nextBase=-s.nextBase
     s.baseLast=t
     s.lastSignal=t
     if type(playTone)=='function' then
      local freq=(s.legs>=10) and 1350 or 1150
      if t-s.penLast<85 and s.penLast>0 then s.pendingBaseTone=freq;s.pendingBaseAt=t+85
      else playTone(freq,(s.legs>=10) and 350 or 85,0,PLAY_NOW or 0) end
     end
     if s.legs==9 and type(playFile)=='function' then
      -- A base signal is vital; queue speech until it has sounded.
      s.pendingRaceVoice='lastleg';s.pendingRaceVoiceAt=t+55
     end
     if s.legs>=10 then
      s.runEnd=t
      if type(playFile)=='function' then
       s.pendingRaceVoice='finish';s.pendingRaceVoiceAt=t+55
      end
     end
    end
   end
   -- Original single flyby sample: only when crossing directly in front of the pilot.
   -- No repeated sound loops, so competition tones are not continuously masked.
   -- Pass direction may be either left-to-right or right-to-left.
   -- Start the flyby ~22 m before crossing the pilot, in either direction.
   -- Single-peak sample with smooth attack and release; no repetition inside the WAV.
   local approachingCenter=(oldX< -22 and nx>= -22) or (oldX>22 and nx<=22)
   local pilotDistance=sqrt(nx*nx+(ny-.8)*(ny-.8)+(nz-24)*(nz-24))
   if approachingCenter and pilotDistance<85 and s.velocity>=28
       and t-s.lastWhistle>=280 and t-s.lastSignal>=75
       and s.pendingBaseTone==0 and type(playFile)=='function' then
    playFile('/SOUNDS/es/pf3fpass.wav')
    s.lastWhistle=t
   end
  end
  -- No automatic teleport at x=+/-220 m (or elsewhere).
  -- Flying beyond base A/B for launch setup is permitted; SH resets explicitly.
 end
 if s.pendingBaseTone>0 and t>=s.pendingBaseAt and type(playTone)=='function' then
  playTone(s.pendingBaseTone,(s.pendingBaseTone==1350) and 350 or 110,0,PLAY_NOW or 0)
  s.pendingBaseTone=0;s.lastSignal=t
 end
 -- Delayed end-of-race announcements: keep the base beep first.
 -- Do not displace a base tone waiting for a penalty sound to finish.
 if s.pendingRaceVoice and t>=s.pendingRaceVoiceAt
     and s.pendingBaseTone==0 and t-s.lastSignal>=45 then
  if type(playFile)=='function' then
   playFile('/SOUNDS/es/POCKETF3F/'..s.pendingRaceVoice..'.wav')
  end
  s.pendingRaceVoice=nil
 end
 local r=s.zone or {};local x=r.x or 0;local y=r.y or 0
 local w=r.w or LCD_W;local h=r.h or LCD_H
 if w<90 or h<70 then return end
 -- World locked camera: pilot never moves, only looks towards the aircraft.
 local ex=s.x;local ey=s.y-0.8;local ez=s.z-24
 local dist=sqrt(ex*ex+ey*ey+ez*ez)
 local az=math.atan2(ex,-ey);local elev=math.atan2(ez,sqrt(ex*ex+ey*ey))
 local ca=cos(az);local sa=sin(az);local ce=cos(elev);local se=sin(elev)
 local focal=math.min(w*1.05,h*1.10)
 local cx=x+w*.5;local cy=y+h*.52
 local function proj(px,py,pz)
  local dx=px;local dy=py-0.8;local dz=pz-24
  local f=-dy*ca+dx*sa
  local right=dx*ca+dy*sa
  local up=dz*ce-f*se
  local depth=f*ce+dz*se
  if depth<2 then return nil end
  return {cx+right*focal/depth,cy-up*focal/depth,depth}
 end
 -- Cheap horizon responds to camera pitch; no large polygons behind camera.
 lcd.drawFilledRectangle(x,y,w,h,SKY)
 local horizon=lim(math.floor(cy+focal*math.tan(elev)),y,y+h)
 if horizon<y+h then lcd.drawFilledRectangle(x,horizon,w,y+h-horizon,SEA) end
 -- Four terrain planes in real world coordinates, with near-plane clipping.
 -- The pilot is at (0,0.8,24); the ridge edge is y=0 at z=20.
 -- A triangle with a vertex behind the camera must be clipped, NOT discarded.
 local function cameraPoint(px,py,pz)
  local dx=px; local dy=py-0.8; local dz=pz-24
  local f=-dy*ca+dx*sa
  local right=dx*ca+dy*sa
  local up=dz*ce-f*se
  return {right,up,f*ce+dz*se}
 end
 local function clipPoly(poly)
  local out={};local near=2
  for i=1,#poly do
   local a=poly[i]; local b=poly[i % #poly+1]
   local ia=a[3]>=near;local ib=b[3]>=near
   if ia then out[#out+1]=a end
   if ia~=ib then
    local t2=(near-a[3])/(b[3]-a[3])
    out[#out+1]={a[1]+(b[1]-a[1])*t2,a[2]+(b[2]-a[2])*t2,near}
   end
  end
  return out
 end
 local function groundQuad(yNear,zNear,yFar,zFar,col)
  local corners={cameraPoint(-280,yNear,zNear),cameraPoint(280,yNear,zNear),
    cameraPoint(280,yFar,zFar),cameraPoint(-280,yFar,zFar)}
  local clipped=clipPoly(corners)
  if #clipped<3 then return end
  -- Restrict extreme projected vertices to a region around the LCD.
  -- EdgeTX no longer receives triangles with 12000-pixel coordinates.
  local xmin=x-w; local xmax=x+2*w
  local ymin=y-h; local ymax=y+2*h
  local pts={}
  -- Project once and reject polygons outside the visible widget.
  -- Never call EdgeTX filled-triangle for a fully offscreen triangle.
  local lowX,highX,lowY,highY=100000,-100000,100000,-100000
  for i=1,#clipped do
   local q=clipped[i]
   local px=lim(math.floor(cx+q[1]*focal/q[3]),xmin,xmax)
   local py=lim(math.floor(cy-q[2]*focal/q[3]),ymin,ymax)
   pts[i]={px,py}
   if px<lowX then lowX=px end
   if px>highX then highX=px end
   if py<lowY then lowY=py end
   if py>highY then highY=py end
  end
  if highX<x or lowX>x+w or highY<y or lowY>y+h then return end
  local p0=pts[1]
  for i=2,#pts-1 do
   local p1=pts[i];local p2=pts[i+1]
   if not ((p0[1]<x and p1[1]<x and p2[1]<x)
        or (p0[1]>x+w and p1[1]>x+w and p2[1]>x+w)
        or (p0[2]<y and p1[2]<y and p2[2]<y)
        or (p0[2]>y+h and p1[2]>y+h and p2[2]>y+h)) then
    triangle(p0,p1,p2,col)
   end
  end
 end
 -- Sea is drawn by the horizon background; overlay a sandy shoreline,
 -- a sloping cliff and the flat land on top of it.
 groundQuad(-67,0,-33,0,SAND)
 groundQuad(-33,0,0,20,CLIFF)
 groundQuad(0,20,350,20,LAND)
 -- A visible world-anchored ridge line and a few depth cues.
 local function lineWorld(xa,ya,za,xb,yb,zb,col)
  local a=cameraPoint(xa,ya,za);local b=cameraPoint(xb,yb,zb)
  if a[3]<2 and b[3]<2 then return end
  if a[3]<2 or b[3]<2 then
   local t2=(2-a[3])/(b[3]-a[3])
   local q={a[1]+(b[1]-a[1])*t2,a[2]+(b[2]-a[2])*t2,2}
   if a[3]<2 then a=q else b=q end
  end
  lcd.drawLine(lim(math.floor(cx+a[1]*focal/a[3]),x-w,x+2*w),
    lim(math.floor(cy-a[2]*focal/a[3]),y-h,y+2*h),
    lim(math.floor(cx+b[1]*focal/b[3]),x-w,x+2*w),
    lim(math.floor(cy-b[2]*focal/b[3]),y-h,y+2*h),SOLID,col)
 end
 lineWorld(-280,0,20,280,0,20,WHITE)
 -- Extra guide lines omitted to reduce LCD draw calls.
 -- Bases anchored in world coordinates. Draw them only when in front.
 for _,bx in ipairs({-50,50}) do
  local foot=proj(bx,1,20);local head=proj(bx,1,34)
  if foot and head then
   local xx=math.floor(foot[1]);local y0=math.floor(foot[2]);local yy=math.floor(head[2])
   lcd.drawLine(xx,yy,xx,y0,SOLID,WHITE)
   lcd.drawLine(xx+1,yy,xx+1,y0,SOLID,WHITE)
   local ya=math.floor(yy+(y0-yy)*.28);local yb=math.floor(yy+(y0-yy)*.54)
   lcd.drawLine(xx,ya,xx,yb,SOLID,TIP)
   lcd.drawLine(xx+1,ya,xx+1,yb,SOLID,TIP)
  end
 end
 -- Glider local axes. Model dimensions: 3.8m span, 1.75m length.
 local a=s.heading;local b=s.bank;local p=s.pitch
 local forward={sin(a)*cos(p),-cos(a)*cos(p),sin(p)}
 -- Proper orthonormal aircraft axes at any pitch/bank.
 -- Previous version projected a false bank when climbing/descending.
 local rightLevel={cos(a),sin(a),0}
 local upLevel={-sin(a)*sin(p),cos(a)*sin(p),cos(p)}
 local wing={rightLevel[1]*cos(b)+upLevel[1]*sin(b),
             rightLevel[2]*cos(b)+upLevel[2]*sin(b),
             upLevel[3]*sin(b)}
 local up={upLevel[1]*cos(b)-rightLevel[1]*sin(b),
           upLevel[2]*cos(b)-rightLevel[2]*sin(b),
           upLevel[3]*cos(b)}
 local function vp(f,v,u)
  return {s.x+forward[1]*f+wing[1]*v+up[1]*u,
          s.y+forward[2]*f+wing[2]*v+up[2]*u,
          s.z+forward[3]*f+wing[3]*v+up[3]*u}
 end
 local function pp(f,v,u)
  local q=vp(f*3.5,v*3.5,u*3.5);return proj(q[1],q[2],q[3])
 end
 -- Magnification applies ONLY to visual model dimensions.
 -- True perspective continues to reduce image size with distance.
 local visualScale=3.5
 local nose=pp(1.0,0,0);local tail=pp(-.85,0,0)
 local lw=pp(0,-1.9,0);local rw=pp(0,1.9,0)
 local root1=pp(.10,0,0);local root2=pp(-.23,0,0)
 if lw and rw and root1 and root2 then
  local normal={up[1],up[2],up[3]}
  local toEye={-ex,-ey,-ez}
  local side=normal[1]*toEye[1]+normal[2]*toEye[2]+normal[3]*toEye[3]
  local col=side>=0 and TOP or BOTTOM
  triangle(lw,rw,root1,col);triangle(lw,rw,root2,col)
  local tipL=pp(0,-1.65,0);local tipR=pp(0,1.65,0)
  if tipL then lcd.drawLine(math.floor(lw[1]),math.floor(lw[2]),math.floor(tipL[1]),math.floor(tipL[2]),SOLID,TIP) end
  if tipR then lcd.drawLine(math.floor(rw[1]),math.floor(rw[2]),math.floor(tipR[1]),math.floor(tipR[2]),SOLID,TIP) end
 end
 if nose and tail then
  lcd.drawLine(math.floor(nose[1]),math.floor(nose[2]),math.floor(tail[1]),math.floor(tail[2]),SOLID,INK)
 end
 -- T-tail: vertical fin attached to fuselage and elevated horizontal stabilizer.
 -- All points use the SAME local 3D axes and camera as the wing.
 local finBase=pp(-.76,0,.02)
 local finTop=pp(-.78,0,.49)
 local finFront=pp(-.59,0,.04)
 if finBase and finTop and finFront then
  triangle(finBase,finTop,finFront,INK)
  lcd.drawLine(math.floor(finBase[1]),math.floor(finBase[2]),math.floor(finTop[1]),math.floor(finTop[2]),SOLID,WHITE)
 end
 local tl=pp(-.78,-.34,.49)
 local tr=pp(-.78,.34,.49)
 local tc=pp(-.68,0,.49)
 local te=pp(-.90,0,.49)
 if tl and tr and tc and te then
  triangle(tl,tr,tc,WHITE)
  triangle(tl,tr,te,WHITE)
  lcd.drawLine(math.floor(tl[1]),math.floor(tl[2]),math.floor(tr[1]),math.floor(tr[2]),SOLID,INK)
 end
 s.frames=s.frames+1
 if t-s.timer>=100 then
  s.fps=math.floor(s.frames*100/(t-s.timer)+.5);s.timer=t;s.frames=0
 end
 lcd.drawText(x+6,y+3,'POCKET F3F BETA',SMLSIZE+INK)
 lcd.drawText(x+6,y+20,'FPS '..s.fps..' A '..math.floor(ail*100)..' E '..math.floor(ele*100)..' B '..math.floor(s.bank*180/pi),SMLSIZE+INK)
 local f3fText
 if s.runEnd then
  f3fText=string.format('META 10/10  %.2fs',(s.runEnd-s.runStart)/100)
 elseif s.entered then
  f3fText=string.format('F3F %d/10  %.2fs  SIG %s',s.legs,(t-s.runStart)/100,s.nextBase==-1 and 'A' or 'B')
 elseif s.runStart then
  f3fText=string.format('TIEMPO +%.1fs  ENTRA A>B',(t-s.runStart)/100)
 else
  local remain=math.max(0,30-(t-s.prepStart)/100)
  if remain>0 then f3fText=string.format('PREP %.0fs',math.ceil(remain))
  else f3fText='ENTRA POR A HACIA B' end
 end
 lcd.drawText(x+6,y+35,f3fText,SMLSIZE+INK)
 if s.penalties>0 then lcd.drawText(x+6,y+50,'AVISOS TRASEROS '..s.penalties,SMLSIZE+INK) end
 lcd.drawText(x+6,y+h-21,'V '..math.floor(s.velocity*3.6+.5)..'km/h H '..math.floor(s.z)..'m L '..string.format('%.1f',s.lift)..' SH',SMLSIZE+INK)
 if s.crashed then
  lcd.drawFilledRectangle(x+math.floor(w*.25),y+math.floor(h*.43),math.floor(w*.50),36,INK)
  lcd.drawText(x+math.floor(w*.28),y+math.floor(h*.45),'IMPACTO - SH REINICIA',SMLSIZE+WHITE)
 end
end
return {name='F3FTEST',options={},create=create,refresh=refresh}
